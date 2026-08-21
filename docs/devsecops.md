# DevSecOps Pipeline

## CI Quality Gates

- Unit tests: pure logic such as question generation and account authentication.
- Integration tests: Phoenix LiveView login, routing, quiz flow, SQLite-backed result persistence, and Notion/OpenBao client boundaries.
- End-to-end tests: recommended before production for the real browser flow from login to completing a subject.

## Security Gates

- `mix deps.audit`: checks Elixir dependencies for known vulnerabilities.
- `mix sobelow --config`: Phoenix static security scan.
- `gitleaks`: prevents committed secrets.
- `trivy`: scans the final Docker image for high and critical vulnerabilities.
- Dependabot: creates update PRs for Mix and GitHub Actions dependencies.

## Dependabot Maintenance Flow

Dependabot version-update PRs target `maintenance/dependabot` instead of `main`.

Use this rhythm:

1. Review and merge safe Dependabot PRs into `maintenance/dependabot`.
2. Let CI run on each Dependabot PR.
3. Periodically open one PR from `maintenance/dependabot` into `main`.
4. Merge that PR after checks pass.
5. A production image is published only when the maintenance branch is merged into `main`.

This keeps dependency updates easy to collect without publishing a new production image for every small Dependabot PR.

## Image Strategy

The Docker image is multi-stage:

- build stage: contains Mix, compiler tools, source code, and dependencies.
- runtime stage: contains only Debian runtime libraries, the Phoenix release, SQLite, CA certificates, and a non-root user.

The final image runs as `kids_prep`, not root.

## Coolify Deployment

Coolify should deploy the image:

```text
ghcr.io/1a-khan/kids-prep:latest
```

Set the public domain:

```text
kids-prep.miak-it.com
```

Set Notion OAuth redirect URL:

```text
https://kids-prep.miak-it.com/auth/notion/callback
```

Use a persistent volume for:

```text
/app/data
```

Run database migrations before starting:

```bash
/app/bin/migrate && /app/bin/server
```

## Runtime Secrets

Coolify should not hold Notion page IDs, database IDs, OAuth client credentials, OAuth token responses, or learner/admin passwords directly when OpenBao is available.

Use OpenBao paths under:

```text
secret/coolify/kids-prep
```

Recommended records:

```text
secret/coolify/kids-prep/notion/config
secret/coolify/kids-prep/notion/oauth
secret/coolify/kids-prep/notion/tokens
secret/coolify/kids-prep/login/users
```

The current app reads Notion config, OAuth config, and Notion token data from OpenBao. Login passwords are environment-backed and should be injected from OpenBao through Coolify or moved to a direct OpenBao-backed hash store before public exposure.

## OpenBao Bootstrap

The app still needs an identity to read OpenBao. Avoid long-lived broad tokens. Use:

- AppRole with policy `kids-prep`.
- A secret ID with limited uses and a bounded TTL where practical.
- Rotation when deploying or after staff/device changes.

Coolify env:

```text
OPENBAO_ADDR
OPENBAO_ROLE_ID
OPENBAO_SECRET_ID
OPENBAO_APPROLE_AUTH_PATH=approle
OPENBAO_KV_MOUNT=secret
OPENBAO_APP_SECRET_PATH=coolify/kids-prep
```

The app exchanges `role_id` + `secret_id` for a short-lived OpenBao client token and caches it until shortly before expiry. If that token expires, the app logs in again with AppRole. If AppRole credentials are invalid or revoked, Notion sync and result push fail closed and local generated material is used where possible.
