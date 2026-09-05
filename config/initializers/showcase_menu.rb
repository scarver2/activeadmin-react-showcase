# config/initializers/showcase_menu.rb
# frozen_string_literal: true

ActiveAdmin.setup do |config|
  config.comments = false

  config.namespace :admin do |admin|
    admin.build_menu :default do |menu|
      menu.add label: "Overview", priority: 10
      menu.add label: "Data & Reporting", priority: 20
      menu.add label: "Operations", priority: 30
      menu.add label: "Collaboration", priority: 40
      menu.add label: "Assets", priority: 50
      menu.add label: "Developer Tools", priority: 60
    end
  end
end
