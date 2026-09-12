# spec/services/social_graph_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe SocialGraph::Explorer do
  let(:admin) { create(:admin_user) }
  let!(:people) { SocialGraph::Seed.call(admin_user: admin) }
  it "projects cycles, mutuals, and the shortest bounded path without duplicate edges" do
    root = people.find { |person| person.name == "Avery Chen" }
    target = people.find { |person| person.name == "June Park" }
    graph = described_class.new(admin_user: admin, root_id: root.id, target_id: target.id, depth: 3).as_json
    expect(graph[:path]).to eq([ root.id.to_s, people.find { |person| person.name == "Diego Flores" }.id.to_s, target.id.to_s ])
    expect(graph[:mutuals].map { |person| person[:name] }).to contain_exactly("Diego Flores", "Imani Brooks")
    expect(graph[:edges].map { |edge| edge[:id] }).to eq(graph[:edges].map { |edge| edge[:id] }.uniq)
  end
  it "returns no path for a disconnected person and handles a self path" do
    root = people.first
    disconnected = people.find { |person| person.name == "Priya Shah" }
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
  end
end
