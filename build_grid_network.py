import os

import pandas as pd
from sqlalchemy import create_engine
from shapely.geometry import shape

# %% Get lines.
engine = create_engine(os.environ['NEON_DB'], pool_recycle=300)
with engine.connect() as c:
    lines = pd.read_sql("select * from public.transmission_lines;", c)

# %%
