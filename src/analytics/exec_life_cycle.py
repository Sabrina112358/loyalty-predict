# %%

import pandas as pd
import sqlalchemy 

import datetime
from tqdm import tqdm


# %%

def import_query(path):
    with open(path) as open_file:
        query = open_file.read()
    return query

query = import_query("/home/sabrina/Documents/projetos/loyalty-predict/src/analytics/life_cycle.sql")

# %%
engine_app = sqlalchemy.create_engine("sqlite:///../../data/loyalty-system/database.db")
engine_analytical = sqlalchemy.create_engine("sqlite:///../../data/analytics/database.db")
# %%

def date_range(start, stop):
    dates = []
    while start <= stop:
         dates.append(start)
         dt_start = datetime.datetime.strptime(start, '%Y-%m-%d') + datetime.timedelta(days=1)
         start = datetime.datetime.strftime(dt_start, '%Y-%m-%d')
    return dates

dates = date_range('2025-09-01', '2025-12-01')

# %%
for date in tqdm(dates):

    with engine_analytical.connect() as conn:
            try:            
                query_del = f"DELETE FROM life_cycle WHERE dtRef = date('{date}', '-1 day')"
                conn.execute(sqlalchemy.text(query_del))
                conn.commit()
            except Exception as e:
                print(f"Error deleting data for {date}: {e}")

                 
            # print(f"Importing data for {date}...")
            df = pd.read_sql_query(query.format(date=date), engine_app)
            df.to_sql("life_cycle", engine_analytical, if_exists="append", index=False)

