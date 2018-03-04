ruby '2.4.0'

source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem 'rest-client'
gem 'rails', '~> 5.1.4'
gem 'puma', '~> 3.7'
gem 'money'

# Fintech Providers
gem 'ynab', github: 'scottrobertson/ynab-sdk-ruby'
gem 'starling-ruby', require: 'starling'

# Utilities
gem 'awesome_print'

group :development, :test do
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'dotenv-rails'
end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
