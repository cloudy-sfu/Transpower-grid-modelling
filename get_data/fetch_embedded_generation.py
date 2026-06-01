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

from postgresql_ops import upsert

logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] [%(levelname)s] %(message)s",
    datefmt='%Y-%m-%d %H:%M:%S',
    stream=sys.stdout,
)

# %% Get power generation load list.
with open("headers/emi.json") as f:
    header_1 = json.load(f)
session = Session()
response = session.get(
    "https://www.emi.ea.govt.nz/Wholesale/Datasets/Metered_data/Embedded_generation",
    headers=header_1, timeout=3
)
web_page = BeautifulSoup(response.text, "html.parser")

# %% Get existed year and month in database.
engine = create_engine(os.environ['NEON_DB'], pool_recycle=300)
with open("sqls/get_year_month.sql") as f:
    sql_get_year_month = f.read()
# pandas doesn't support dynamic table name
sql_get_year_month = sql_get_year_month.replace(":table_name", "embedded_generation")
with engine.connect() as c:
    year_month = pd.read_sql(sql_get_year_month, c)
year_month = year_month['year_month'].tolist()

# %% Parse month archive.
with open("headers/emidatasets.json") as f:
    header_2 = json.load(f)
chunk_size = 2000


def grid_flow_multiplier(s):
    if s == "X":
        return -1
    elif s == "I":
        return 1
    else:
        return 0


for row in tqdm(web_page.find("table").find_all('tr', recursive=False)):
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
                continue
        a_href_1 = ("https://emidatasets.blob.core.windows.net/publicdata/Datasets/"
                    "Wholesale/Metered_data/Embedded_generation/") + fn
        response = session.get(a_href_1, headers=header_2, timeout=3)
        response.raise_for_status()
        csv_io = io.StringIO(response.text)
        load = pd.read_csv(csv_io)
        load.rename(columns={
            "NWK_Code": "Nwk_Code",
            'GENERATION_TYPE': "Generation_Type",
            "TRADING_DATE": "Trading_Date",
            "Trading_date": "Trading_Date",
            'TRADER': 'Trader',
            'FLOW_DIRECTION': 'Flow_Direction'
        }, inplace=True)

        # Remove non-ASCII characters
        load.columns = load.columns.str.replace(r'[^\x00-\x7f]', '', regex=True)

        # Combine flow direction
        load['Flow_Direction'] = load['Flow_Direction'].apply(grid_flow_multiplier)

        # Get electricity load
        load = pd.melt(
            frame=load,
            id_vars=["POC", "Flow_Direction", "Trading_Date"],
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

        # Aggregate traders
        load['load'] = load['load'] * load['Flow_Direction']
        load.rename(columns={"POC": "poc"}, inplace=True)
        load = load[['poc', 'end_time', 'load']]
        load = load.groupby(['poc', 'end_time']).sum().reset_index()

        for i in range(0, load.shape[0], chunk_size):
            upsert(
                engine,
                load.iloc[i:i + chunk_size, :],
                ['poc', 'end_time'],
                "embedded_generation"
            )

    except Exception as e:
        logging.warning(f"Fail to download file {a_href}\n"
                        f"Reason: {e}")
        continue
