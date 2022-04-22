#                Copyright 2019 Motorola Solutions, Inc.
#                           All Rights Reserved.
#
#                Motorola Solutions Confidential Restricted
FROM elixir:latest

RUN mkdir /app
WORKDIR /app


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
RUN mix compile
RUN mix release rakv



ENTRYPOINT START_RA_CLUSTER=${START_RA_CLUSTER} _build/dev/rel/rakv/bin/rakv start


