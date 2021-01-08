FROM ruby:2.7.1
WORKDIR /app

RUN gem install bundler -v 2.1.4
ADD Gemfile* /app/
RUN bundle check || bundle install --jobs=4 --retry=3

ADD . /app

ENTRYPOINT bundle exec puma -C config/puma.rb
