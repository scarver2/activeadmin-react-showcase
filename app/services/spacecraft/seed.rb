# app/services/spacecraft/seed.rb
# frozen_string_literal: true

module Spacecraft
  class Seed
    def self.call(admin_user:)
      admin_user.spacecraft_models.find_or_create_by!(name: "Odyssey engineering demonstrator")
    end
  end
end
