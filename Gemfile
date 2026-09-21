# Gemfile
# frozen_string_literal: true

source "https://rubygems.org"

gem "activeadmin", "4.0.0.beta22"
gem "activeadmin-react", "0.2.0", git: "https://github.com/scarver2/activeadmin-react.git",
    ref: "40ac735f8307152bedafd06101cedbc0f93b1130", require: false
gem "activeadmin-themes", "0.2.0.pre",
    git: "https://github.com/scarver2/activeadmin-themes.git",
    ref: "a74d0cd04f328c52e176319e5fcee6f424c66498",
    require: false
gem "ancestry", "5.1.0"
gem "bootsnap", require: false
gem "devise"
gem "image_processing", "~> 1.2"
gem "jbuilder"
gem "kamal", require: false
gem "paper_trail", "17.0.0"
gem "paper_trail_diff", "0.12.0"
gem "propshaft"
gem "puma", ">= 5.0"
gem "rails", "8.1.3.1"
gem "seedbank", "0.5.0",
    git: "https://github.com/scarver2/seedbank.git",
    ref: "12449f33997f463d5b56f90b605dafc0a7065bff"
gem "solid_cache"
gem "solid_cable"
gem "solid_queue"
gem "sqlite3", ">= 2.1"
gem "thruster", require: false
gem "turbo-rails"
gem "tzinfo-data", platforms: %i[jruby windows]
gem "vite_rails", "3.11.1"

group :development, :test do
  gem "brakeman", require: false
  gem "bundler-audit", require: false
  gem "capybara"
  gem "climate_control"
  gem "database_cleaner-active_record"
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "factory_bot_rails"
  gem "guard-rspec", require: false
  gem "guard-rubocop", require: false
  gem "rbs", require: false
  gem "rspec-rails"
  gem "rubocop-rails-omakase", require: false
  gem "shoulda-matchers"
  gem "simplecov", require: false
end

group :development do
  gem "foreman", require: false
  gem "letter_opener_web", "3.0.0"
  gem "ruby-lsp", require: false
  gem "ruby-lsp-rails", require: false
  gem "web-console"
end
