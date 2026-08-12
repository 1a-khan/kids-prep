# Mustafa & Mihrimah Gymnasium Prep

Phoenix LiveView practice app for Mihrimah and Mustafa as they move from Turkiye to Germany.

It includes German, English, and Maths daily practice, instant explanations for wrong answers, saved quiz results in SQLite, and a retry playground for missed questions. Admins can also review an in-app performance dashboard with progress bars, trends, weak skills, and the current adaptive level per child and subject.

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

| User | OpenBao key | Access |
| --- | --- | --- |
| `mihrimah` | `mihrimah_password` | Mihrimah's own subjects and results |
| `mustafa` | `mustafa_password` | Mustafa's own subjects and results |
| `admin` | `admin_password` | Both children, recent results, and Notion connect |

Store production passwords in OpenBao:

```bash
bao kv put secret/coolify/kids-prep/login/users \
  mihrimah_password="your_mihrimah_password" \
  mustafa_password="your_mustafa_password" \
  admin_password="your_admin_password"
```

Local development can still use the `KIDS_PREP_*_PASSWORD` env vars from `.env.example` as a fallback. Do not commit real passwords to GitHub.

## Generate local daily material

```bash
mix kids_prep.material.generate
mix kids_prep.material.generate 2026-09-01
```

Generated JSON files are written to `priv/generated_material/YYYY-MM-DD/`.

## Notion sync

I created a Notion hub page and four databases in the workspace `Notion von Ammad Khan`.

Runtime Notion IDs are loaded from OpenBao, not Coolify env:

```bash
bao kv put secret/coolify/kids-prep/notion/config \
  hub_page_id="your_hub_page_id" \
  questions_database_id="your_questions_database_id" \
  daily_modules_database_id="your_daily_modules_database_id" \
  results_database_id="your_results_database_id" \
  weak_skills_database_id="your_weak_skills_database_id"
```

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
export OPENBAO_ROLE_ID=your_approle_role_id
export OPENBAO_SECRET_ID=your_approle_secret_id
export OPENBAO_APPROLE_AUTH_PATH=approle
export OPENBAO_KV_MOUNT=secret
export OPENBAO_APP_SECRET_PATH=coolify/kids-prep
export OPENBAO_NOTION_SECRET_PATH=kids-prep/notion
export OPENBAO_NOTION_TOKEN_FIELD=notion_token
mix phx.server
```

`NOTION_TOKEN` still works as a direct override, but OpenBao is preferred so the Notion secret is not stored in local project files.

The app also accepts Vault/OpenBao CLI-style names: `BAO_ADDR`, `BAO_TOKEN`, `VAULT_ADDR`, and `VAULT_TOKEN`.

For Coolify, keep env vars limited to bootstrap/runtime necessities:

- `PHX_HOST`
- `PORT`
- `DATABASE_PATH`
- `SECRET_KEY_BASE`
- `OPENBAO_ADDR`
- `OPENBAO_ROLE_ID`
- `OPENBAO_SECRET_ID`
- `OPENBAO_APPROLE_AUTH_PATH`
- `OPENBAO_KV_MOUNT`
- `OPENBAO_APP_SECRET_PATH`

All app-level Notion config should be under:

```text
secret/coolify/kids-prep/notion/config
secret/coolify/kids-prep/notion/oauth
secret/coolify/kids-prep/notion/tokens
```

OpenBao tokens can expire. Do not use your personal/root token in Coolify. For production, use AppRole with a policy scoped only to `secret/data/coolify/kids-prep/*`.

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

The app includes a background scheduler. When a Notion token is available through OAuth, OpenBao, or `NOTION_TOKEN`, it retries unsynced SQLite results, prepares today's and tomorrow's daily modules, and refreshes the local SQLite question cache. Notion/API errors are logged as warnings and the children still get local generated questions as a fallback.

Generate today's Notion modules:

```bash
OPENBAO_ADDR=http://127.0.0.1:8200 OPENBAO_ROLE_ID=your_approle_role_id OPENBAO_SECRET_ID=your_approle_secret_id OPENBAO_APP_SECRET_PATH=coolify/kids-prep mix kids_prep.notion.generate_daily
```

Repair existing Deutsch/Mathe question-bank rows so prompts, skills, tips, and explanations are German:

```bash
OPENBAO_ADDR=http://127.0.0.1:8200 OPENBAO_ROLE_ID=your_approle_role_id OPENBAO_SECRET_ID=your_approle_secret_id OPENBAO_APP_SECRET_PATH=coolify/kids-prep mix kids_prep.notion.repair_german_material
```

In a release container such as Coolify, run the same repair through release eval:

```bash
/app/bin/kids_prep eval "KidsPrep.Release.repair_german_material()"
```

Push recent SQLite results to Notion:

```bash
OPENBAO_ADDR=http://127.0.0.1:8200 OPENBAO_ROLE_ID=your_approle_role_id OPENBAO_SECRET_ID=your_approle_secret_id OPENBAO_APP_SECRET_PATH=coolify/kids-prep mix kids_prep.notion.push_results
```

In a release container such as Coolify, push unsynced SQLite results to Notion:

```bash
/app/bin/kids_prep eval "KidsPrep.Release.push_results_to_notion()"
```

When the Notion token is available through OpenBao or `NOTION_TOKEN`, the scheduler prepares Notion modules and warms a local SQLite question cache. The LiveView quiz reads from SQLite first, so children are not waiting on Notion while clicking through the app. If the cache is empty or contains invalid language material, the app falls back to locally generated daily questions.

Admins can click **Fragen aktualisieren** in the app to refresh today's SQLite question cache from Notion after new material is added or corrected.

Admins can click **Ergebnisse synchronisieren** in the app to push unsynced SQLite results into the Notion Results and Weak Skills databases. Result pages are upserted by `Result Key`, and weak-skill pages are upserted by `Weak Skill Key`, so retries do not create duplicate Notion rows.

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
- Local generated questions use a simple adaptive level: after at least two strong recent results in a subject, the next generated set moves one level up for that child and subject. Notion-provided modules remain the source of truth when they exist and pass validation. For a ChatGPT scheduled question generator, read the Notion Results and Weak Skills databases first, then create new question rows that target the weakest skills and increase level only when recent results are consistently strong.
- Results are saved in `kids_prep_dev.db`.
- SQLite is fine for Mustafa and Mihrimah using the app in parallel on one local machine. The app uses WAL mode and a busy timeout so reads and short result writes can coexist comfortably.
- Each subject has enough questions for a focused 45-minute practice block, especially when children read explanations and retry missed questions.
