#                Copyright 2019 Motorola Solutions, Inc.
#                           All Rights Reserved.
#
#                Motorola Solutions Confidential Restricted
FROM elixir:latest


# Required for dependencies
RUN apk add --update alpine-sdk

# Pre-build deps to save time
COPY mix.exs .
COPY mix.lock .

# Build deps
RUN mix deps.get 
RUN mix deps.compile

# Build the rest
COPY Makefile Makefile
COPY config config


COPY lib lib
COPY rel rel

RUN MIX_ENV=prod mix release 

# Post build run container to clear source and credentials
FROM elixir:latest

WORKDIR /app

RUN addgroup -g 10001 -S svcuser && \
    adduser -u 10001 -S svcuser -G svcuser && \
    chown -R svcuser:svcuser /app

COPY --from=builder --chown=svcuser:10001 /artifacts/_build/prod/rel/ra_client ra_client
USER svcuser
ENV HOME /app/ra_client/var

ENTRYPOINT ./ra_client/bin/ra_client start