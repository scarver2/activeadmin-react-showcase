# spec/support/shoulda_matchers.rb
# frozen_string_literal: true

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.library :rails
    with.test_framework :rspec
  end
end
