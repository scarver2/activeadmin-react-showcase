# app/services/social_graph/explorer.rb
# frozen_string_literal: true

module SocialGraph
  class Explorer
    MAXIMUM_DEPTH = 3
    MAXIMUM_EDGES = 100
    MAXIMUM_NODES = 50
    def initialize(admin_user:, root_id:, depth: 1, target_id: nil)
      @people = admin_user.social_people
      @root = @people.find(root_id)
      @target = target_id.present? ? @people.find(target_id) : nil
      @depth = Integer(depth)
      raise ArgumentError, "Depth must be between 1 and #{MAXIMUM_DEPTH}" unless @depth.between?(1, MAXIMUM_DEPTH)
    end
    def as_json
      visited, edges = projection
      { nodes: visited.values.map { |entry| serialize_person(entry.fetch(:person), entry.fetch(:degree)) },
        edges: edges.map { |a, b| { id: "#{a}-#{b}", source: a.to_s, target: b.to_s } },
        mutuals: target ? (root.neighbors & target.neighbors).map { |person| serialize_person(person, nil) } : [],
        path: target ? shortest_path.map(&:to_s) : [] }
    end
    private
    attr_reader :depth, :people, :root, :target
    def projection
      visited = { root.id => { person: root, degree: 0 } }
      frontier = [ root ]
      edges = []
      depth.times do |degree|
        next_frontier = []
        frontier.each do |person|
          person.neighbors.order(:id).each do |neighbor|
            pair = [ person.id, neighbor.id ].sort
            edges << pair unless edges.include?(pair)
            next if visited.key?(neighbor.id) || visited.length >= MAXIMUM_NODES
            visited[neighbor.id] = { person: neighbor, degree: degree + 1 }
            next_frontier << neighbor
          end
        end
        frontier = next_frontier
      end
      [ visited, edges.first(MAXIMUM_EDGES) ]
    end
    def shortest_path
      return [ root.id ] if root == target
      queue = [ [ root.id ] ]
      seen = [ root.id ]
      until queue.empty?
        path = queue.shift
        people.find(path.last).neighbors.each do |neighbor|
          next if seen.include?(neighbor.id)
          candidate = path + [ neighbor.id ]
          return candidate if neighbor == target
          seen << neighbor.id
          queue << candidate if candidate.length <= MAXIMUM_DEPTH + 1
        end
      end
      []
    end
    def serialize_person(person, degree)
      { degree:, headline: person.headline, id: person.id.to_s, name: person.name,
        url: Rails.application.routes.url_helpers.admin_social_person_path(person) }
    end
  end
end
