#                Copyright 2019 Motorola Solutions, Inc.
#                           All Rights Reserved.
#
#                Motorola Solutions Confidential Restricted
FROM elixir:latest AS builder


ARG OAUTH_TOKEN
RUN git config --global url."https://msi-cie:${OAUTH_TOKEN}@dev.azure.com/".insteadOf "https://dev.azure.com/"

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

COPY lib lib
#COPY rel rel

RUN mix release mini_group_call

# Post build run container to clear source and credentials
FROM elixir:latest

WORKDIR /app

RUN addgroup -g 10001 -S svcuser && \
    adduser -u 10001 -S svcuser -G svcuser && \
    chown -R svcuser:svcuser /app

COPY --from=builder --chown=svcuser:10001 /artifacts/_build/dev/rel/mini_group_call mini_group_call
USER svcuser
ENV HOME /app/mini_group_call/var

ENTRYPOINT ./mini_group_call/bin/mini_group_call start