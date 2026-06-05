# Transpower grid modelling
Simulate Transpower gird modelling by PyPSA

![](https://shields.io/badge/dependencies-Python_3.14-blue)



## Install

### Database

Create a [Neon](https://neon.com/) PostgreSQL 18.3 database. "Settings > Compute defaults > Scale to zero" must keep default (5 minutes) or longer.

Setup the database schema by `database_schema.sql`.

>   [!note]
>
>   Any other PostgreSQL database release may work, but is not tested. If using other database, replace the [connection string](https://neon.com/docs/connect/connect-from-any-app) to Neon database by the [connection string](https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-CONNSTRING) to your own PostgreSQL database.

### GitHub Actions

Deploy this program in GitHub and enable GitHub Actions for this repository.

Manually run each scheduled job once, to initially save data into database and ensure all the GitHub Actions are active.

Add the following variables into GitHub repository settings "Secrets and variables > Actions > Secrets > Repository secrets".

| Variable | Description                         |
| -------- | ----------------------------------- |
| NEON_DB  | Connection string to Neon database. |

### Local

Create and activate a Python 3.14 virtual environment.

Set the following environment variables in session level:

| Variable   | Description                         |
| ---------- | ----------------------------------- |
| PYTHONPATH | Constant: `.`                       |
| NEON_DB    | Connection string to Neon database. |

Run the following command in terminal.

```powershell
# install dependencies
pip install -r requirements.txt

# collect data -> initialize or update before analyzing, but don't need regular update
python get_data/fetch_transmission_lines.py
python get_data/fetch_connection_points.py
```

