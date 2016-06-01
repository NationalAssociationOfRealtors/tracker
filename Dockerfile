FROM elixir:1.2.5

RUN apt-get update

RUN mix local.rebar
RUN mix local.hex --force

ADD . /app
WORKDIR /app

RUN mix do deps.get, deps.compile
