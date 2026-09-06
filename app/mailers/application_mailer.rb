# app/mailers/application_mailer.rb
# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: "from@example.com"
  layout "mailer"
end
