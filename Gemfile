source 'https://rubygems.org'

group :test do
  gem 'guard-rspec'
end

group :development do
  # gem 'fattr'
  # gem 'arrayfields'
  # gem 'map'
  # gem 'metrical'
  gem 'rspec'
  gem 'echoe'
end

if RUBY_VERSION < '1.9'
  gem 'activesupport'
  gem 'fastercsv'
  gem 'rake', '~> 0.9.2.2' # required for travis builds
else
  gem 'activesupport'
  gem 'rake'
end
