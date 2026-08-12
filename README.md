# Mustafa & Mihrimah Gymnasium Prep

Phoenix LiveView practice app for Mihrimah and Mustafa as they move from Turkiye to Germany.

It includes German, English, and Maths daily practice, instant explanations for wrong answers, saved quiz results in SQLite, and a retry playground for missed questions.

## Install Elixir/Erlang with Ansible

The playbook is already created:

```bash
ANSIBLE_LOCAL_TEMP=.ansible/tmp ansible-playbook --ask-become-pass playbooks/install_elixir.yml
```

On Ubuntu 26 with `sudo-rs`, the playbook needs the become password prompt because it installs system packages with `apt`.

## Run the app

```bash
mix setup
mix phx.server
```

Then open:

```text
http://localhost:4000
```

## Login accounts

The app requires login before the practice screen opens.

Current accounts:

| User | Password | Access |
| --- | --- | --- |
| `mihrimah` | `KIDS_PREP_MIHRIMAH_PASSWORD` | Mihrimah's own subjects and results |
| `mustafa` | `KIDS_PREP_MUSTAFA_PASSWORD` | Mustafa's own subjects and results |
| `admin` | `KIDS_PREP_ADMIN_PASSWORD` | Both children, recent results, and Notion connect |

Set those values through your shell for local development, and through Coolify/OpenBao for production. Do not commit real passwords to GitHub.

## Generate local daily material

```bash
mix kids_prep.material.generate
mix kids_prep.material.generate 2026-09-01
```

Generated JSON files are written to `priv/generated_material/YYYY-MM-DD/`.

## Notion sync

I created a Notion hub page and four databases in the workspace `Notion von Ammad Khan`:

- Hub: `https://app.notion.com/p/3bab677ed9b4817cab8cf67b40ae961e`
- Questions database: `814ae504b1a4479a9bbf038801e703e7`
- Daily Modules database: `956aa51d67744967be5e6d0e43e2cbed`
- Results database: `54ec1e84f6af4dfeb19f334ddf45cc0d`
- Weak Skills database: `4371e03fafcc4f87bc49a432a4573817`

The preferred setup is Notion OAuth with OpenBao. The app reads OAuth credentials from OpenBao, sends you to Notion for consent, and stores the resulting Notion token response back in OpenBao.

Store the OAuth connection values you created for `OpenBao-integration`:

```bash
bao kv put secret/coolify/kids-prep/notion/oauth \
  client_id="your_notion_oauth_client_id" \
  client_secret="your_notion_oauth_client_secret" \
  authorization_url="your_notion_authorization_url"
```

For a private fallback without OAuth, an internal integration token can also be stored:

```bash
bao kv put secret/kids-prep/notion notion_token=notion_token_placeholder
```

Run the app with OpenBao access:

```bash
export OPENBAO_ADDR=http://127.0.0.1:8200
export OPENBAO_TOKEN=your_openbao_token
export OPENBAO_KV_MOUNT=secret
export OPENBAO_APP_SECRET_PATH=coolify/kids-prep
export OPENBAO_NOTION_SECRET_PATH=kids-prep/notion
export OPENBAO_NOTION_TOKEN_FIELD=notion_token
mix phx.server
```

`NOTION_TOKEN` still works as a direct override, but OpenBao is preferred so the Notion secret is not stored in local project files.

The app also accepts Vault/OpenBao CLI-style names: `BAO_ADDR`, `BAO_TOKEN`, `VAULT_ADDR`, and `VAULT_TOKEN`.

Connect OAuth locally:

```text
http://localhost:4000/auth/notion
```

Notion should redirect back to:

```text
http://localhost:4000/auth/notion/callback
```

After a successful callback, the app writes the OAuth token response to:

```text
secret/coolify/kids-prep/notion/tokens
```

The app includes a background scheduler. When a Notion token is available through OAuth, OpenBao, or `NOTION_TOKEN`, it prepares today's and tomorrow's daily modules. Notion/API errors are logged as warnings and the children still get local generated questions as a fallback.

Generate today's Notion modules:

```bash
OPENBAO_ADDR=http://127.0.0.1:8200 OPENBAO_TOKEN=your_openbao_token OPENBAO_APP_SECRET_PATH=coolify/kids-prep mix kids_prep.notion.generate_daily
```

Push recent SQLite results to Notion:

```bash
OPENBAO_ADDR=http://127.0.0.1:8200 OPENBAO_TOKEN=your_openbao_token OPENBAO_APP_SECRET_PATH=coolify/kids-prep mix kids_prep.notion.push_results
```

When the Notion token is available through OpenBao or `NOTION_TOKEN`, the app tries Notion first for today's module and falls back to local generated questions if Notion is unavailable.

## DevSecOps and deployment

Production domain:

```text
https://kids-prep.miak-it.com
```

Container image target:

```text
ghcr.io/1a-khan/kids-prep:latest
```

The repository includes:

- `.github/workflows/ci.yml` for CI, security checks, Docker image build, image scan, and GHCR publish.
- `.github/dependabot.yml` for dependency update PRs.
- `Dockerfile` with a multi-stage Phoenix release build and non-root runtime user.
- `docker-compose.yml` for Coolify-style image deployment with a persistent SQLite volume at `/app/data`.
- `docs/devsecops.md` with the pipeline and deployment notes.

CI gates:

- `mix format --check-formatted`
- `mix compile --warnings-as-errors`
- `mix test`
- `mix deps.audit`
- `mix sobelow --exit`
- `gitleaks`
- `trivy` image scan

## Notes

- Questions change daily because they are generated from the child, subject, and date.
- Results are saved in `kids_prep_dev.db`.
- SQLite is fine for Mustafa and Mihrimah using the app in parallel on one local machine. The app uses WAL mode and a busy timeout so reads and short result writes can coexist comfortably.
- Each subject has enough questions for a focused 45-minute practice block, especially when children read explanations and retry missed questions.
