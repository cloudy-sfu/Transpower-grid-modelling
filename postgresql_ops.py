from functools import lru_cache

from sqlalchemy import MetaData, Table
from sqlalchemy.dialects.postgresql import insert


@lru_cache(maxsize=None)
def _get_table(engine, table_name, schema):
    """
    Reflect and cache a single table per (engine, table_name, schema).
    Reflecting on every call (the previous behaviour) issued repeated schema
    queries to the remote database, which dominated execution time. Caching
    removes those redundant round-trips. Reflecting only the requested table
    (instead of the whole schema) is a further saving.
    Ref: https://docs.sqlalchemy.org/en/20/core/metadata.html#sqlalchemy.schema.Table
    """
    metadata = MetaData()
    return Table(table_name, metadata, schema=schema, autoload_with=engine)


def upsert(engine, df, unique_key_columns, table_name, schema="public"):
    """
    Performs a bulk INSERT OR UPDATE of a pandas DataFrame to a Postgresql table.
    This function inserts rows from the DataFrame. If a row violates a unique
    constraint (specified by `unique_key_columns`), it updates the
    existing row with the new values from the DataFrame instead.
    """
    if df.empty:
        return
    table = _get_table(engine, table_name, schema)
    # Convert DataFrame to a list of dictionaries for SQLAlchemy
    data_to_insert = df.to_dict(orient='records')
    # The initial INSERT statement
    stmt = insert(table).values(data_to_insert)
    # Dynamically create the 'set_' dictionary for the ON CONFLICT clause.
    # This dictionary maps columns to be updated to the new values from
    # the incoming data (referred to by 'stmt.excluded').
    # We update all columns that are NOT part of the unique key.
    update_cols = {
        col.name: col
        for col in stmt.excluded
        if col.name not in unique_key_columns
    }
    # Construct the final UPSERT statement with the ON CONFLICT clause
    upsert_stmt = stmt.on_conflict_do_update(
        index_elements=unique_key_columns,
        set_=update_cols
    )
    # Execute the statement within a transaction
    with engine.begin() as conn:
        conn.execute(upsert_stmt)


def insert_skip_conflict(engine, df, unique_key_columns, table_name, schema="public"):
    """
    Performs a bulk INSERT of a pandas DataFrame to a Postgresql table.
    If a row violates a unique constraint (specified by `unique_key_columns`),
    that specific row is skipped (ignored), and the non-conflicting rows are inserted.
    """
    if df.empty:
        return
    table = _get_table(engine, table_name, schema)
    # Convert DataFrame to a list of dictionaries for SQLAlchemy
    data_to_insert = df.to_dict(orient='records')
    # The initial INSERT statement
    stmt = insert(table).values(data_to_insert)
    # Construct the statement with ON CONFLICT DO NOTHING
    # We do not need 'set_' here because we simply ignore the conflict.
    do_nothing_stmt = stmt.on_conflict_do_nothing(
        index_elements=unique_key_columns
    )
    # Execute the statement within a transaction
    with engine.begin() as conn:
        conn.execute(do_nothing_stmt)
