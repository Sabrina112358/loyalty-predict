
import pandas as pd
import sqlalchemy 

import datetime
from tqdm import tqdm

import argparse


def import_query(path):
    with open(path) as open_file:
        query = open_file.read()
    return query

def date_range(start, stop, monthly= False):
    dates = []
    while start <= stop:
         dates.append(start)
         dt_start = datetime.datetime.strptime(start, '%Y-%m-%d') + datetime.timedelta(days=1)
         start = datetime.datetime.strftime(dt_start, '%Y-%m-%d')

    if monthly: 
         return [date for date in dates if date.endswith("01")]
    return dates

def exec_query(table, db_origin, db_target, dt_start, dt_stop, monthly):
    engine_app = sqlalchemy.create_engine(f"sqlite:///../../data/{db_origin}/database.db")
    engine_analytical = sqlalchemy.create_engine(f"sqlite:///../../data/{db_target}/database.db")

    query = import_query(f"{table}.sql")
    dates = date_range(dt_start, dt_stop, monthly)

    for date in tqdm(dates):

        with engine_analytical.connect() as conn:
                try:            
                    query_del = f"DELETE FROM {table} WHERE dtRef = date('{date}', '-1 day')"
                    conn.execute(sqlalchemy.text(query_del))
                    conn.commit()
                except Exception as err:
                    print(err)

                    
                df = pd.read_sql_query(query.format(date=date), engine_app)
                df.to_sql(table, engine_analytical, if_exists="append", index=False)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--db_origin", choices=['loyalty-system', 'education-platform', 'analytics'], default='loyalty-system')
    parser.add_argument("--db_target", choices=['analytics'], default='analytics')
    parser.add_argument("--table", type=str, help="Tabela que será processada com o mesmo nome do arquivo")

    now = datetime.datetime.now().strftime("%Y-%m-%d")
    parser.add_argument("--start", type=str, default=now)
    parser.add_argument("--stop", type=str, default=now)

    parser.add_argument("--monthly", action='store_true')
    args = parser.parse_args()

    exec_query(args.table, args.db_origin, args.db_target, args.start, args.stop, args.monthly)

if __name__ == "__main__":
     main()

