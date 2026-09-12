# app/services/social_graph/seed.rb
# frozen_string_literal: true

module SocialGraph
  class Seed
    PEOPLE = { "Avery Chen" => "Aerospace engineer", "Diego Flores" => "Systems designer", "Imani Brooks" => "Research director", "June Park" => "Mission planner", "Maya Singh" => "Materials scientist", "Noah Williams" => "Flight test lead", "Priya Shah" => "Robotics engineer" }.freeze
    EDGES = [ [ "Avery Chen", "Diego Flores" ], [ "Avery Chen", "Imani Brooks" ], [ "Diego Flores", "June Park" ], [ "Imani Brooks", "June Park" ], [ "June Park", "Maya Singh" ], [ "Maya Singh", "Noah Williams" ] ].freeze
    def self.call(admin_user:)
      people = PEOPLE.to_h { |name, headline| [ name, admin_user.social_people.find_or_create_by!(name:) { |person| person.headline = headline } ] }
      EDGES.each do |left, right|
        a, b = [ people.fetch(left), people.fetch(right) ].sort_by(&:id)
        SocialConnection.find_or_create_by!(person_a: a, person_b: b)
      end
      people.values
    end
  end
end
