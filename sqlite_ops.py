from sqlalchemy import MetaData
from sqlalchemy.dialects.sqlite import insert


def upsert(engine, df, unique_key_columns, table_name, schema="main"):
    """
    Performs a bulk INSERT OR UPDATE of a pandas DataFrame to an SQLite table.
    This function inserts rows from the DataFrame. If a row violates a unique
    constraint (specified by `unique_key_columns`), it updates the
    existing row with the new values from the DataFrame instead.
    """
    if df.empty:
        return

    metadata = MetaData()
    metadata.reflect(bind=engine, schema=schema)

    # Format table key based on whether a schema is provided
    table_key = f"{schema}.{table_name}" if schema else table_name
    table = metadata.tables[table_key]

    # Convert DataFrame to a list of dictionaries for SQLAlchemy
    data_to_insert = df.to_dict(orient='records')

    # The initial INSERT statement
    stmt = insert(table).values(data_to_insert)

    # Dynamically create the 'set_' dictionary for the ON CONFLICT clause.
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


def insert_skip_conflict(engine, df, unique_key_columns, table_name, schema="main"):
    """
    Performs a bulk INSERT of a pandas DataFrame to an SQLite table.
    If a row violates a unique constraint (specified by `unique_key_columns`),
    that specific row is skipped (ignored), and the non-conflicting rows are inserted.
    """
    if df.empty:
        return

    metadata = MetaData()
    metadata.reflect(bind=engine, schema=schema)

    # Format table key based on whether a schema is provided
    table_key = f"{schema}.{table_name}" if schema else table_name
    table = metadata.tables[table_key]

    # Convert DataFrame to a list of dictionaries for SQLAlchemy
    data_to_insert = df.to_dict(orient='records')

    # The initial INSERT statement
    stmt = insert(table).values(data_to_insert)

    # Construct the statement with ON CONFLICT DO NOTHING
    do_nothing_stmt = stmt.on_conflict_do_nothing(
        index_elements=unique_key_columns
    )

    # Execute the statement within a transaction
    with engine.begin() as conn:
        conn.execute(do_nothing_stmt)