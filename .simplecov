# .simplecov
# frozen_string_literal: true

SimpleCov.configure do
  skip "/config/"
  skip "/db/"
  skip "/spec/"
  skip "app/mailers/application_mailer.rb"

  group "Admin", "app/admin"
  group "Models", "app/models"
  group "Services", "lib/showcase"

  enable_coverage :branch
  minimum_coverage line: 90, branch: 80
end
