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
