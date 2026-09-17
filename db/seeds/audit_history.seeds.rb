# db/seeds/audit_history.seeds.rb
# frozen_string_literal: true

after :admin do
  admin = AdminUser.find_by!(email: ENV.fetch("SHOWCASE_ADMIN_EMAIL", "admin@example.test"))
  AuditHistory::Seed.call(admin_user: admin)
end
