# app/services/social_graph/seed.rb
# frozen_string_literal: true

module SocialGraph
  class Seed
    PEOPLE = {
      "Luke Skywalker" => "Rebel hero and Jedi",
      "Darth Vader" => "Former Jedi and Luke's father",
      "Leia Organa" => "Rebel leader and Luke's twin",
      "Obi-Wan Kenobi" => "Jedi mentor across generations",
      "Yoda" => "Jedi Grand Master",
      "Han Solo" => "Rebel pilot and Leia's partner",
      "Ben Solo / Kylo Ren" => "Leia and Han's son",
      "Rey" => "Jedi apprentice of Luke",
      "Finn" => "Resistance hero and Rey's ally",
      "Ahsoka Tano" => "Anakin's former apprentice",
      "Padme Amidala" => "Senator and mother of Luke and Leia"
    }.freeze
    EDGES = [
      [ "Luke Skywalker", "Darth Vader", "father and son" ],
      [ "Luke Skywalker", "Leia Organa", "twins" ],
      [ "Darth Vader", "Leia Organa", "father and daughter" ],
      [ "Obi-Wan Kenobi", "Darth Vader", "former mentor" ],
      [ "Obi-Wan Kenobi", "Luke Skywalker", "mentor" ],
      [ "Yoda", "Obi-Wan Kenobi", "mentor" ],
      [ "Leia Organa", "Han Solo", "partners" ],
      [ "Leia Organa", "Ben Solo / Kylo Ren", "mother and son" ],
      [ "Han Solo", "Ben Solo / Kylo Ren", "father and son" ],
      [ "Luke Skywalker", "Ben Solo / Kylo Ren", "mentor" ],
      [ "Luke Skywalker", "Rey", "mentor" ],
      [ "Rey", "Finn", "allies" ],
      [ "Darth Vader", "Ahsoka Tano", "former mentor" ],
      [ "Padme Amidala", "Darth Vader", "partners" ],
      [ "Padme Amidala", "Luke Skywalker", "mother and son" ],
      [ "Padme Amidala", "Leia Organa", "mother and daughter" ]
    ].freeze

    def self.call(admin_user:)
      people = PEOPLE.to_h { |name, headline| [ name, admin_user.social_people.find_or_create_by!(name:) { |person| person.headline = headline } ] }
      EDGES.each do |left, right, label|
        a, b = [ people.fetch(left), people.fetch(right) ].sort_by(&:id)
        SocialConnection.find_or_initialize_by(person_a: a, person_b: b).tap do |connection|
          connection.label = label
          connection.save!
        end
      end
      people.values
    end
  end
end
