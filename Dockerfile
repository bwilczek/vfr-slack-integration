FROM ruby:2.3.1-slim

COPY . /app
WORKDIR /app

RUN bundle install

EXPOSE 4567

CMD [ "bundle", "exec", "ruby", "server.rb" ]
