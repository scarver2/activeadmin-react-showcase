# db/seeds/social_graph.seeds.rb
# frozen_string_literal: true

after :admin do
  admin = AdminUser.find_by!(email: ENV.fetch("SHOWCASE_ADMIN_EMAIL", "admin@example.test"))
  SocialGraph::Seed.call(admin_user: admin)
end
