# spec/models/social_person_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe SocialPerson do
  it { is_expected.to belong_to(:admin_user) }
  it { is_expected.to validate_presence_of(:headline) }
  it { is_expected.to validate_presence_of(:name) }
  it "lists neighbors in either canonical edge position" do
    owner = create(:admin_user)
    people = Array.new(3) { create(:social_person, admin_user: owner) }
    SocialConnection.create!(person_a: people[0], person_b: people[1])
    SocialConnection.create!(person_a: people[1], person_b: people[2])
    expect(people[1].neighbors).to contain_exactly(people[0], people[2])
  end
  it("allowlists searches") { expect(described_class.ransackable_attributes).to include("name") }
end
