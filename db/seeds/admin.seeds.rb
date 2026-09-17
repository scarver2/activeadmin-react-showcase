# db/seeds/admin.seeds.rb
# frozen_string_literal: true

admin_email = ENV.fetch("SHOWCASE_ADMIN_EMAIL", "admin@example.test")
admin_password = ENV["SHOWCASE_ADMIN_PASSWORD"]

if admin_password.blank?
  raise "SHOWCASE_ADMIN_PASSWORD is required in production" if Rails.env.production?

  admin_password = "showcase-password"
end

admin = AdminUser.find_or_initialize_by(email: admin_email)
admin.update!(password: admin_password, password_confirmation: admin_password)
