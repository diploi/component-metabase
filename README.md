<img alt="icon" src=".diploi/icon.svg" width="32">

# Metabase Component for Diploi

[![launch with diploi badge](https://diploi.com/launch.svg)](https://diploi.com/component/metabase)
[![component on diploi badge](https://diploi.com/component.svg)](https://diploi.com/component/metabase)
[![latest tag badge](https://badgen.net/github/tag/diploi/component-metabase)](https://diploi.com/component/metabase)

Launch a trial, no account needed
https://diploi.com/component/metabase

Uses the official [metabase/metabase](https://hub.docker.com/r/metabase/metabase) Docker image as it is (Metabase 65). The version is the `images[].image` tag in `diploi.yaml`.

Requires **PostgreSQL**, which is included as a Diploi add-on. Metabot, Metabase's AI assistant, runs on the Diploi AI proxy, so it works without an API key of your own.

## Operation

### Getting started

1. In the Dashboard, click **Create Project +**
2. Under **Pick Components**, choose **Metabase**

   Add **Odoo** here too if you want to analyze your Odoo data. Metabase connects to it on its first start.
3. In **Pick Add-ons**, PostgreSQL is required and selected by default.
4. Choose **Create Repository** so Diploi generates a new GitHub repo for your project.
5. Click **Launch Stack**

### Login

Log in with the email and password under **Admin login** in the deployment's **Setup** tab. The email is `admin@example.com` by default, and the password is generated for every project.

Change both in Metabase's account settings after the first login. The Setup tab's values are only read on the first start.

### First start

A `setup` container runs beside Metabase in its pod. On every start it creates Metabase's own database (**Database name** in the Setup tab, default `metabase`) on the PostgreSQL add-on if it is missing, and Metabase waits for that. When Metabase first starts on an empty database, the container also sets it up:

1. Waits for Metabase to answer.
2. Creates the admin user from **Admin login**.
3. Looks for an Odoo database on the add-on. If there is one, Metabase connects to it. If not, Metabase connects to the add-on's own database (`POSTGRES_DB`, default `app`).
4. Creates the `metabase_reader` role, which can read every table in that database but change nothing. Metabase queries the database as this role. Tables the database's owner creates later are readable too, such as those of a new Odoo module.
5. Creates the API key `Diploi agent` in the Administrators group, which gives the prompt tab's agent a Metabase user of its own. See [Prompt tab](#prompt-tab).

Later starts skip steps 2 to 5. The script lives in the component's helm files (`.diploi/helm/app-scripts.yaml`), so it is updated with the component rather than being frozen in the user project. The `setup` container is a plain Alpine that installs `psql`, `jq` and `curl` when it starts, which takes a few seconds.

If the setup fails, the `setup` container's log says why. Finish it in the browser: Metabase shows its setup wizard while there is no admin user, and databases are added in **Admin > Databases**.

### Odoo

Odoo's tables are in the `public` schema. Fields that Odoo translates, such as product and partner names, are stored as JSON with one value per language, so in SQL read them as `name->>'en_US'`.

Metabase checks for Odoo only on its first start. If Odoo was added to the project later, or was still being created at that moment, add it in **Admin > Databases > Add database**. Choose **PostgreSQL**, and use the host and port from `MB_DB_HOST` and `MB_DB_PORT`, and the database name, user and password from the Odoo component's `DATABASE`, `USER` and `PASSWORD`.

### Metabot

Metabot uses the Diploi AI proxy, and its use is billed to your Diploi account as AI usage. It runs on Claude Sonnet 5.5. The AI provider is set through environment variables, so **Admin > AI** shows it as read-only.

- The **Metabot** switch in the Setup tab turns all of Metabase's AI features on or off. Its two fields choose the models.
- To use your own Anthropic key instead, set `MB_LLM_ANTHROPIC_API_KEY` to it and `MB_LLM_ANTHROPIC_API_BASE_URL` to `https://api.anthropic.com` in the **Environment** tab.

### Prompt tab

The agent in the Diploi prompt tab can use Metabase's [MCP server](https://www.metabase.com/docs/latest/ai/mcp), so you can ask it to explore your data, answer questions with SQL, and create questions, dashboards, collections and alerts. It acts as the user of the API key `Diploi agent`, which is in the Administrators group.

The agent reaches the MCP server with the **Access token** under **Prompt tab** in the Setup tab. The Diploi core adds the token to the agent's requests, so it never reaches the development environment. Metabase does not issue a token that lasts, so every start writes this one into Metabase's database, for its OAuth client `Diploi agent`.

- **The agent reads data as `metabase_reader`**, like everyone in Metabase, so it cannot change Odoo's or the add-on's data.
- **To switch its access off**, turn off **Prompt tab** in the Setup tab. The token is revoked, and the API key stays.
- **To rotate the token**, change the **Access token**. The old token is revoked.
- **To revoke its access inside Metabase**, delete the API key `Diploi agent` in **Admin > Settings > Authentication > API keys**. The token stops working at once. To restore it, create an API key named `Diploi agent` in the Administrators group, and restart the component.

### Storage

Metabase keeps all of its data in its PostgreSQL database, so the component has no volumes. Back up the add-on to back up Metabase.

### Setup tab

The deployment's **Setup** tab holds the values a project chooses. Each is also an environment variable of the containers.

| Group           | Field                   | Variable                   | Description                                                                                                  |
| --------------- | ----------------------- | -------------------------- | ------------------------------------------------------------------------------------------------------------ |
| Admin login     | Email                   | `INITIAL_ADMIN_EMAIL`      | Email address of the admin user created on the first start. Default `admin@example.com`.                     |
| Admin login     | Password                | `INITIAL_ADMIN_PASSWORD`   | Password of that user. Generated per project.                                                                |
| Database        | Database name           | `MB_DB_DBNAME`             | Metabase's own database on the PostgreSQL add-on. Default `metabase`.                                        |
| Database        | Reader password         | `READER_PASSWORD`          | Password of the read-only `metabase_reader` role. Generated per project. Only read on the first start.       |
| Database        | Sample database         | `MB_LOAD_SAMPLE_CONTENT`   | Include Metabase's sample database. Default on.                                                              |
| Keys            | Encryption key          | `MB_ENCRYPTION_SECRET_KEY` | Encrypts the connection details of the databases Metabase queries. Generated per project. Never change it.   |
| Keys            | Session key             | `MB_SESSION_SECRET_KEY`    | Signs login sessions. Generated per project. Changing it logs everyone out.                                  |
| Metabot         | the switch              | `MB_AI_FEATURES_ENABLED`   | All of Metabase's AI features. Default on.                                                                   |
| Metabot         | Model                   | `MB_LLM_METABOT_PROVIDER`  | The model Metabot runs on. Default `anthropic/claude-sonnet-5-5`.                                            |
| Metabot         | Model for short tasks   | `MB_LLM_MINI_MODEL`        | The model for short tasks, such as naming a conversation. Default `anthropic/claude-sonnet-5-5`.             |
| Prompt tab      | the switch              | `DIPLOI_AGENT_ENABLED`     | Whether the prompt tab's agent may use Metabase's MCP server. Default on.                                    |
| Prompt tab      | Access token            | `METABASE_AGENT_TOKEN`     | The agent's access token for the MCP server. Generated per project.                                          |

### Environment variables

| Variable                        | Description                                                                                  |
| ------------------------------- | -------------------------------------------------------------------------------------------- |
| `MB_SITE_URL`                   | The public address of Metabase, from the component's host. Used in links and redirects.      |
| `MB_LLM_ANTHROPIC_API_BASE_URL` | The Diploi AI proxy, which Metabot calls.                                                    |
| `MB_LLM_ANTHROPIC_API_KEY`      | The deployment's AI proxy token.                                                             |
| `MB_LLM_ALLOWED_NETWORKS`       | `allow-private`, so that Metabase may call the AI proxy on the deployment's private network. |
| `MB_ANON_TRACKING_ENABLED`      | `false`. Metabase sends no usage data.                                                       |
| `MB_CHECK_FOR_UPDATES`          | `false`. Diploi decides the Metabase version.                                                |

PostgreSQL connection details (`MB_DB_HOST`, `MB_DB_PORT`, `MB_DB_USER`, `MB_DB_PASS`, `POSTGRES_DB`) come from the PostgreSQL add-on.

Any other [Metabase environment variable](https://www.metabase.com/docs/latest/configuring-metabase/environment-variables) can be added in the **Environment** tab. A setting set this way is read-only in Metabase's admin.

### Development and production

Every stage runs the same upstream image, and Metabase serves on port **3000**. There is nothing to build: this folder holds no code, and Metabase is configured in its admin, in the Setup tab and through environment variables. To move to another Metabase version, change the image tag in `diploi.yaml`.

The first start migrates Metabase's database, which can take a few minutes on a small core. The deployment waits for `/api/health` before it sends traffic to a new version.

## Links

- [Metabase documentation](https://www.metabase.com/docs/latest/)
- [Metabase AI settings](https://www.metabase.com/docs/latest/ai/settings)
- [Metabase environment variables](https://www.metabase.com/docs/latest/configuring-metabase/environment-variables)
