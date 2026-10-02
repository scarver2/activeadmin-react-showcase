# spec/services/showcase/contextual_relationships_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Showcase::ContextualRelationships do
  let(:explorer) { described_class.new(admin_user: create(:admin_user)) }

  it "starts with immediate context and expands deterministically across all seven kinds" do
    expect(explorer.graph.fetch(:nodes).pluck(:id)).to eq(%w[customer contact order])
    graph = explorer.graph(depth: 3)
    expect(graph).to eq(explorer.graph(depth: "3"))
    expect(graph.fetch(:nodes).pluck(:kind).sort).to eq([ "Contact", "Conversation", "Customer", "File", "Order", "Project", "Work Item" ])
    expect(graph.fetch(:nodes).pluck(:id).uniq.size).to eq(graph.fetch(:nodes).size)
    expect(graph.fetch(:edges).pluck(:label)).to include("placed", "reviews", "references")
    graph.fetch(:nodes).each { |node| expect(node.fetch(:url)).to include("?source=#{node.fetch(:id)}") }
  end

  it "omits unavailable endpoints and denies direct access without leaking fields" do
    serialized = explorer.graph(depth: 3).to_json
    expect(serialized).not_to match(/Restricted order|Deleted draft|missing|Must not be projected/)
    %w[restricted deleted missing].each { |id| expect { explorer.find(id) }.to raise_error(ActiveRecord::RecordNotFound) }
    expect { described_class.new(admin_user: nil) }.to raise_error(ActiveRecord::RecordNotFound)
    expect { described_class.new(admin_user: build(:admin_user)) }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "rejects invalid bounds and unavailable roots" do
    [ 0, 4, "abc" ].each { |depth| expect { explorer.graph(depth:) }.to raise_error(ArgumentError) }
    expect { explorer.graph(root: "restricted") }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "caps high fanout and cycles while excluding dangling edges" do
    nodes = Array.new(60) { |index| { id: index.to_s, kind: "Work", name: "Synthetic #{index}", detail: "Demo" } }
    edges = Array.new(59) { |index| [ "0", (index + 1).to_s, "includes" ] }
    edges += Array.new(30) { |index| [ "1", (index + 2).to_s, "related" ] }
    graph = described_class.new(admin_user: create(:admin_user), nodes:, edges:).graph(root: "0", depth: 3)
    expect(graph.fetch(:nodes).size).to eq(24)
    expect(graph.fetch(:edges).size).to eq(40)
    expect(graph.fetch(:bounded)).to be(true)
    ids = graph.fetch(:nodes).pluck(:id)
    expect(graph.fetch(:edges).all? { |edge| ids.include?(edge.fetch(:source)) && ids.include?(edge.fetch(:target)) }).to be(true)
  end
end
