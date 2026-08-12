# syntax=docker/dockerfile:1

ARG ELIXIR_VERSION=1.18.3
ARG OTP_VERSION=27.3.4.3
ARG BUILD_DEBIAN_VERSION=bookworm-20250929-slim
ARG RUNTIME_DEBIAN_VERSION=bookworm-slim

FROM hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${BUILD_DEBIAN_VERSION} AS build

RUN apt-get update -y \
  && apt-get install -y --no-install-recommends build-essential git ca-certificates \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

ENV MIX_ENV=prod

RUN mix local.hex --force \
  && mix local.rebar --force

COPY mix.exs mix.lock ./
COPY config config
RUN mix deps.get --only prod
RUN mix deps.compile

COPY lib lib
COPY priv priv
COPY rel rel

RUN mix compile
RUN mix release

FROM debian:${RUNTIME_DEBIAN_VERSION} AS runtime

RUN apt-get update -y \
  && apt-get install -y --no-install-recommends ca-certificates libstdc++6 openssl libncurses6 sqlite3 \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && groupadd --system --gid 10001 kids_prep \
  && useradd --system --uid 10001 --gid kids_prep --home-dir /app --shell /usr/sbin/nologin kids_prep

WORKDIR /app

ENV HOME=/app
ENV MIX_ENV=prod
ENV PHX_SERVER=true
ENV PORT=4000
ENV DATABASE_PATH=/app/data/kids_prep_prod.db

COPY --from=build --chown=kids_prep:kids_prep /app/_build/prod/rel/kids_prep ./

RUN mkdir -p /app/data \
  && chown -R kids_prep:kids_prep /app \
  && chmod +x /app/bin/migrate /app/bin/server

USER kids_prep

EXPOSE 4000

CMD ["/app/bin/server"]
