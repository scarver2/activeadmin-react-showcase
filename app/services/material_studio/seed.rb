# app/services/material_studio/seed.rb
# frozen_string_literal: true

module MaterialStudio
  class Seed
    def self.call(admin_user:)
      admin_user.material_spheres.find_or_create_by!(name: "Glossy red material sphere")
    end
  end
end
