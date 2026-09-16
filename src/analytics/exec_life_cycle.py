# %%

import pandas as pd
import sqlalchemy 


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

dates = {
        '2024-06-01',
        '2024-07-01',
        '2024-08-01',
        '2024-09-01',
        '2024-10-01',
        '2024-11-01',
        '2024-12-01',
        '2025-05-01', 
        '2025-06-01', 
        '2025-07-01', 
        '2025-08-01', 
        '2025-09-01', 
        '2025-10-01', 
        '2025-11-01', 
        '2025-12-01', 
        '2026-01-01', 
        '2026-02-01', 
        '2026-03-01', 
        '2026-04-01', 
        '2026-05-01', 
        '2026-06-01', 
        '2026-07-01', 
        '2026-08-01', 
        '2026-09-01'
}

for date in dates:

    with engine_analytical.connect() as conn:
            try:            
                query_del = f"DELETE FROM life_cycle WHERE dtRef = date('{date}', '-1 day')"
                conn.execute(sqlalchemy.text(query_del))
                conn.commit()
            except Exception as e:
                print(f"Error deleting data for {date}: {e}")

                 
            print(f"Importing data for {date}...")
            df = pd.read_sql_query(query.format(date=date), engine_app)
            df.to_sql("life_cycle", engine_analytical, if_exists="append", index=False)

    
# %%
