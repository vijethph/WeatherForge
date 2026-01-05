source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.0"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Bundle and transpile JavaScript [https://github.com/rails/jsbundling-rails]
gem "jsbundling-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Action Cable, and Active Job
gem "solid_cache"
gem "solid_cable"
gem "solid_queue"

# Background job processing with Sidekiq 8.x
# Requires Redis 7.0+ (using Redis 8.2-alpine via Docker)
gem "sidekiq", "~> 8.1"
gem "sidekiq-scheduler", "~> 6.0"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Audits gems for known security defects (use config/bundler-audit.yml to ignore issues)
  gem "bundler-audit", require: false

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", "~> 7.1", ">= 7.1.2", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
end

gem "redis", "~> 5.4", ">= 5.4.1"
gem "pg", "~> 1.6", ">= 1.6.2"
gem "httparty", "~> 0.23.2"
gem "chartkick", "~> 5.2", ">= 5.2.1"
gem "bootstrap", "~> 5.3", ">= 5.3.5"
gem "dartsass-rails", "~> 0.5.1"
gem "rubocop", "~> 1.82", ">= 1.82.1"
gem "rubocop-rails", "~> 2.34", ">= 2.34.2"
gem "rubocop-rspec", "~> 3.8"
gem "better_errors", "~> 2.10", ">= 2.10.1"
gem "binding_of_caller", "~> 1.0", ">= 1.0.1"
gem "lograge", "~> 0.14.0"
gem "dotenv-rails", "~> 3.2"
gem "rswag", "~> 2.17"
gem "activerecord-postgis-adapter", "~> 11.1", ">= 11.1.1"
gem "rgeo", "~> 3.0", ">= 3.0.1"
gem "rgeo-geojson", "~> 2.2"
gem "geocoder", "~> 1.8", ">= 1.8.6"


gem "rspec-rails", "~> 8.0", ">= 8.0.2", group: [ :development, :test ]
gem "factory_bot_rails", "~> 6.5", ">= 6.5.1", group: [ :development, :test ]
gem "faker", "~> 3.5", ">= 3.5.3", group: [ :development, :test ]
gem "shoulda-matchers", "~> 7.0", group: :test
gem "kaminari", "~> 1.2", ">= 1.2.2"
gem "webmock", "~> 3.26", ">= 3.26.1"
