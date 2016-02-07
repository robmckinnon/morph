source 'https://rubygems.org'

group :test do
  gem 'guard-rspec'
end

group :development do
  gem 'rspec'
end

if RUBY_VERSION < '1.9'
  gem 'i18n', '0.6.11'
  gem 'activesupport', '~> 3.2.0'
  gem 'fastercsv'
  gem 'rake', '~> 0.9.2.2' # required for travis builds
else
  gem 'activesupport'
  gem 'rake'
end
