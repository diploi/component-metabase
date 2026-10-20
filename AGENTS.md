# Metabase

[Metabase](https://www.metabase.com/docs/latest/) 65, the business intelligence tool, from the official
`metabase/metabase` image (`FROM` in `Dockerfile`).

## This component

- There is no code here. Questions, dashboards, users and database connections live in Metabase's own PostgreSQL
  database (`MB_DB_DBNAME`, default `metabase`, on the `postgres` add-on), not in this repository. Change them in
  Metabase's admin or through the [Metabase API](https://www.metabase.com/docs/latest/api), never by editing that
  database.
- Configuration is environment variables, set in the deployment's **Environment** tab. Every `MB_*` variable is a
  [Metabase setting](https://www.metabase.com/docs/latest/configuring-metabase/environment-variables) and is
  read-only in Metabase's admin while it is set. A change takes effect when the component restarts.
- Serves on port **3000** in every stage. Every stage runs the same image, built from `Dockerfile`.
- On the first start, the component creates the admin user and connects Metabase to Odoo's database if the add-on
  has one, or else to the add-on's `POSTGRES_DB`. Metabase reads that database as the read-only role
  `metabase_reader`. `README.md` describes the steps and how to add a database later.
- Login is `INITIAL_ADMIN_EMAIL` with `INITIAL_ADMIN_PASSWORD`. Both are only read on the first start. The password
  is a secret: point the user to the **Environment** tab, never print it.
- Never change `MB_ENCRYPTION_SECRET_KEY`: Metabase could no longer read the connection details it encrypted with it.
- Metabase's MCP server is among your tools when this component is in the project. It acts as the Metabase user of
  the API key `Diploi agent`, an admin. Prefer its tools to the REST API, and call its `learn` tool for Metabase's
  task guides before a complex write such as a dashboard with filters. Its queries read data as `metabase_reader`,
  so they cannot change it. Do not change Metabase's settings, users or permissions unless the user asks for it.
- Metabot runs on Claude through the Diploi AI proxy (`MB_LLM_*` variables), billed to the user's Diploi account.

## Diploi

AI-oriented platform docs: <https://docs.diploi.com/llms-full.txt>. Do not speculate about undocumented Diploi
behavior, link to the docs instead.

- Env vars imported from other components are live in the container. List them with `printenv` instead of
  guessing, and never print secret values.
- `diploi logs <identifier> --follow` streams logs. `diploi exec <identifier> -- <command>` runs a command in
  another component's container. `psql` is in this component's image.
