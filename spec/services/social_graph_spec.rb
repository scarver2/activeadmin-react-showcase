# spec/services/social_graph_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe SocialGraph::Explorer do
  let(:admin) { create(:admin_user) }
  let!(:people) { SocialGraph::Seed.call(admin_user: admin) }
  it "projects cycles, mutuals, and the shortest bounded path without duplicate edges" do
    root = people.find { |person| person.name == "Luke Skywalker" }
    target = people.find { |person| person.name == "Darth Vader" }
    graph = described_class.new(admin_user: admin, root_id: root.id, target_id: target.id, depth: 3).as_json
    expect(graph[:path]).to eq([ root.id.to_s, target.id.to_s ])
    expect(graph[:mutuals].map { |person| person[:name] }).to contain_exactly("Leia Organa", "Obi-Wan Kenobi", "Padme Amidala")
    expect(graph[:edges]).to include(hash_including(label: "father and son", source: root.id.to_s, target: target.id.to_s))
    expect(graph[:edges].map { |edge| edge[:id] }).to eq(graph[:edges].map { |edge| edge[:id] }.uniq)
  end

  it "finds a cross-generation path within the three-degree cap" do
    root = people.find { |person| person.name == "Ben Solo / Kylo Ren" }
    target = people.find { |person| person.name == "Finn" }
    graph = described_class.new(admin_user: admin, root_id: root.id, target_id: target.id, depth: 3).as_json
    names = graph[:path].map { |id| SocialPerson.find(id).name }
    expect(names).to eq([ "Ben Solo / Kylo Ren", "Luke Skywalker", "Rey", "Finn" ])
  end
  it "returns no path for a disconnected person and handles a self path" do
    root = people.first
    disconnected = create(:social_person, admin_user: admin, name: "Disconnected Observer")
    expect(described_class.new(admin_user: admin, root_id: root.id, target_id: disconnected.id, depth: 3).as_json[:path]).to be_empty
    expect(described_class.new(admin_user: admin, root_id: root.id, target_id: root.id).as_json[:path]).to eq([ root.id.to_s ])
  end
  it "rejects traversal bounds and other owners" do
    expect { described_class.new(admin_user: admin, root_id: people.first.id, depth: 4) }.to raise_error(ArgumentError, /Depth/)
    expect { described_class.new(admin_user: create(:admin_user), root_id: people.first.id) }.to raise_error(ActiveRecord::RecordNotFound)
  end
  it("seeds idempotently") { expect { SocialGraph::Seed.call(admin_user: admin) }.not_to change(SocialConnection, :count) }
end

RSpec.describe SocialConnection do
  it "rejects duplicate direction, reverse order, and mixed ownership" do
    owner = create(:admin_user)
    a = create(:social_person, admin_user: owner)
    b = create(:social_person, admin_user: owner)
    left, right = [ a, b ].sort_by(&:id)
    create(:social_connection, person_a: left, person_b: right)
    expect(build(:social_connection, person_a: left, person_b: right)).not_to be_valid
    expect(build(:social_connection, person_a: right, person_b: left)).not_to be_valid
    expect(build(:social_connection, person_a: left, person_b: create(:social_person))).not_to be_valid
    expect(build(:social_connection, person_a: left, person_b: right, label: "")).not_to be_valid
  end
end
