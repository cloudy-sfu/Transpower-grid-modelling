import io
import json
import logging
import os
import re
import sys

import pandas as pd
from bs4 import BeautifulSoup
from requests import Session
from sqlalchemy import create_engine
from tqdm import tqdm

from postgresql_ops import upsert, insert_skip_conflict

logging.basicConfig(
    level=logging.WARNING,
    format="[%(levelname)s] %(message)s",
    stream=sys.stdout,
)

# %% Get power generation load list.
with open("headers/emi.json") as f:
    header_1 = json.load(f)
session = Session()
response = session.get(
    "https://www.emi.ea.govt.nz/Wholesale/Datasets/Generation/Generation_MD",
    headers=header_1, timeout=3
)
web_page = BeautifulSoup(response.text, "html.parser")

# %% Get existed year and month in database.
engine = create_engine(
    os.environ['NEON_DB'],
    pool_recycle=300,
    executemany_mode="values_plus_batch",
)
with open("sqls/get_year_month.sql") as f:
    sql_get_year_month = f.read()
# pandas doesn't support dynamic table name
sql_get_year_month = sql_get_year_month.replace(":table_name", "generation")
with engine.connect() as c:
    year_month = pd.read_sql(sql_get_year_month, c)
year_month = year_month['year_month'].tolist()

# %% Parse month archive.
with open("headers/emidatasets.json") as f:
    header_2 = json.load(f)
chunk_size = 2000
retries = 0
rows = web_page.find("table").find_all('tr', recursive=False)
pbar = tqdm(desc="Generation", total=len(rows))
for row in rows:
    a_href = row.find('a').get('href')
    try:
        # Download data
        fn = str(a_href).split("/")[-1]
        match_ = re.search(r"^(\d{6})", fn)
        if match_:
            year_month_this = match_.group(1)
            year_month_this = year_month_this[:4] + "-" + year_month_this[4:]
            if year_month_this in year_month:
                logging.info(f"Month {year_month_this} existed in the database, skipped.")
                pbar.total -= 1
                continue
        a_href_1 = ("https://emidatasets.blob.core.windows.net/publicdata/Datasets/"
                    "Wholesale/Generation/Generation_MD/") + fn
        response = session.get(a_href_1, headers=header_2, timeout=3)
        response.raise_for_status()
        csv_io = io.StringIO(response.text)
        load = pd.read_csv(csv_io)
        # Remove non-ASCII characters
        load.columns = load.columns.str.replace(r'[^\x00-\x7f]', '', regex=True)
        load.rename(columns={
            "NWK_Code": "Nwk_Code",
            "TRADING_DATE": "Trading_Date",
            "Trading_date": "Trading_Date",
            'TRADER': 'Trader',
            'FLOW_DIRECTION': 'Flow_Direction',
            "Gen_Code": "gen_code",
            "POC_Code": "poc",
            "Fuel_Code": "fuel_code"
        }, inplace=True)

        # Get unique generators
        generator = (load[["gen_code", "poc", "fuel_code"]]
                     .drop_duplicates(ignore_index=True))
        insert_skip_conflict(
            engine,
            generator,
            ["gen_code"],
            "generator"
        )

        # Get electricity load
        load = pd.melt(
            frame=load,
            id_vars=["gen_code", "Trading_Date", "Nwk_Code"],
            value_vars=[col for col in load.columns if col.startswith('TP')],
            var_name='TP',
            value_name='load'
        )
        load.dropna(subset=['load'], inplace=True)
        load['TP'] = load['TP'].str.extract(r'(\d+)', expand=False).astype('Int64')
        if "/" in load.loc[0, "Trading_Date"]:
            # pandas parse as "%m/%d/%Y" by default, which needs manual definition
            trading_date_data = pd.to_datetime(load["Trading_Date"], format="%d/%m/%Y")
        else:
            trading_date_data = pd.to_datetime(load["Trading_Date"])
        load['end_time'] = (trading_date_data.dt.tz_localize('Pacific/Auckland')
                            + pd.Timedelta(minutes=30) * load['TP'])
        load['end_time'] = load['end_time'].dt.tz_convert('UTC')
        load = load[['gen_code', 'end_time', 'load']]
        # aggregate Nwk_Code
        load = load.groupby(['gen_code', 'end_time']).sum().reset_index()
        for i in range(0, load.shape[0], chunk_size):
            upsert(
                engine,
                load.iloc[i:i+chunk_size, :],
                ['gen_code', 'end_time'],
                "generation"
            )
        pbar.update(1)

    except Exception as e:
        logging.warning(f"Fail to download file {a_href}\n"
                        f"Reason: {e}")
        retries += 0.2
        if retries > 1:
            raise Exception("Stop because of too many failed instances.")
        else:
            continue
