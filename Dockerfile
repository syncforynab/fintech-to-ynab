FROM ruby:2.4.0
WORKDIR /app

ADD Gemfile* /app/
RUN bundle check || bundle install --jobs=4 --retry=3

ADD . /app

ENTRYPOINT bundle exec puma -C config/puma.rb
