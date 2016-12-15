FROM ruby:2.3.1-slim

COPY . /app
WORKDIR /app

RUN apt-get update && apt-get install -y build-essential && rm -rf /var/lib/apt/lists/*

RUN bundle install
