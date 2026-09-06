# spec/support/database_cleaner.rb
# frozen_string_literal: true

require "database_cleaner/active_record"

RSpec.configure do |config|
  config.before(:suite) { DatabaseCleaner.clean_with(:truncation) }
  config.before { |example| DatabaseCleaner.strategy = example.metadata.fetch(:database_cleaner, :transaction) }
  config.before { DatabaseCleaner.start }
  config.after { DatabaseCleaner.clean }
end
