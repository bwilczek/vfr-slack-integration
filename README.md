## Introduction

This software is a backend for Slack integration that responds to slash commands with aeronautical data. It was created only as a Proof of Concept and is not deployed to 'production' anywhere. Feel free to use it if you want to build a Slack Application on top of it.

## Functionality

This application provides aeronautical data (NOTAM, METAR, TAF) for requested aerodromes.

#### Pre-requisite

"Slash Commands" Configuration has to be defined for this app on Slack's side (manage your organization). Let's assume that slash command `/vfr` was chosen.

#### Using it in chat

```
# retrieve NOTAMs for single aerodrome (defined by ICAO code)
/vfr notam KJFK

# retrieve METAR for multiple aerodromes
/vfr metar EPWR EPPO EPWA

# retrieve TAF for single aerodromes
/vfr metar EPWR
```

## Architecture

From technical perspective this whole application can be described as Slack interface to Ruby gem [`vfr_utils`](https://github.com/bwilczek/vfr_utils). There are however few components involved to make more user friendly by reducing latency.

#### Data flow

* User enters command into chat: `/vfr notam LKLB`
* Slack processes it and sends a POST request with `param[:text]=="notam LKLB"` to *HTTP endpoint*
* *HTTP endpoint* immediately replies with text "Hold on, requested data will arrive soon..." and adds an entry to `RabbitMQ` queue.
* *Worker deamon* picks the entry from queue and spawns a thread which processes the entry
* The new thread uses gem `vfr_utils` to fetch the data and posts it back to `response_url` provided by Slack in initial message.
* Gem `vfr_utils` internally caches the aeronautical data to reduce requests to external services

#### Summary

The involved components are:
* RabbitMQ
* HTTP endpoint (part of this repo)
* Worker deamon (part of this repo)

Both *HTTP endpoint* and *Worker deamon* are provided as a docker container image (`Dockerfile` to be more precise).

The design is asynchronous (message bus, concurrent request processing) to minimize latency for the end users.

## Deployment

Before this application is started Slack integration (Slash Command Configuration) has to be set up first. It is there where endpoint URL and authentication token are defined.

Both HTTP endpoint and worker are dockerized in the same container image.
Which application is being started is decided on `docker run` execution.

Before the application is executed the container has to be build using the following command:

```
docker build -t vfr-slack-integration .
```

#### RabbitMQ

Since `RabbitMQ` is the communication medium between the components it also has to be running before the containers are started. The easiest way to run it would be of course `docker`:
```
docker run -d \
  --hostname rabbit \
  --name rabbit \
  -e RABBITMQ_ERLANG_COOKIE='<YOUR_ERLANG_COOKIE_HERE>' \
  rabbitmq:3
```

#### Starting HTTP endpoint

The containerized `Sinatra` app running on port 4567 has to be exposed to public, so that
Slack could access it. The URL of the endpoint is configured on Slack's end.
Exposing the service can be achieved in an elegant way using [nginx-proxy](https://github.com/jwilder/nginx-proxy). Or directly using port redirection (`-p 80:4567`). Or any other way of your preference.

The following environment variables can be used to define connection to `RabbitMQ`. Default values in parenthesis

* VFR_RABBIT_QUEUE_NAME ('vfr-utils')
* VFR_RABBIT_HOST ('127.0.0.1')
* VFR_RABBIT_VHOST ('/')
* VFR_RABBIT_PORT (5672)
* VFR_RABBIT_USER ('guest')
* VFR_RABBIT_PASS ('guest')

In the listing below HTTP endpoint container is using `RabbitMQ` service which runs in another container (`rabbit`). Please mind the required port exposition and use of `SLACK_TOKEN` variable (obtained from Slack's Slash Commands Configuration).

```
docker run -d \
  --name vfr-endpoint \
  --link rabbit \
  --expose 4567 \
  -e VFR_RABBIT_HOST=rabbit \
  -e SLACK_TOKEN=<YOUR_TOKEN_HERE> \
  vfr-slack-integration \
  bundle exec ruby endpoint.rb
```

#### Starting worker daemon

Worker process accepts the same environment variables for Slack authentication and `RabbitMQ` connection as the previous one. Additionally it accepts variable to define logging level: `VFR_LOG_LEVEL`. It accepts values compatible with Ruby's `Logger` class, so: `unknown`, `fatal`, `error`, `warn`, `info`, `debug`.

```
docker run -d \
  --name vfr-worker \
  --link rabbit \
  -e VFR_RABBIT_HOST=rabbit \
  -e VFR_LOG_LEVEL=info \
  -e SLACK_TOKEN=<YOUR_TOKEN_HERE> \
  vfr-slack-integration \
  bundle exec ruby worker.rb
```

Worker application log is being saved in `/var/log/vfr_slack_integration.log` and can be accessed from inside the container.
