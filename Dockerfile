FROM ruby:2.6.5
WORKDIR /app

RUN gem install bundler -v 1.17.1
ADD Gemfile* /app/
RUN bundle check || bundle install --jobs=4 --retry=3

ADD . /app

ENTRYPOINT bundle exec puma -C config/puma.rb
