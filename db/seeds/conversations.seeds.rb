# db/seeds/conversations.seeds.rb
# frozen_string_literal: true

after :admin do
  if Conversations::Availability.enabled?
    admin = AdminUser.find_by!(email: ENV.fetch("SHOWCASE_ADMIN_EMAIL", "admin@example.test"))
    Conversations::Seed.call(admin_user: admin)
  end
end
