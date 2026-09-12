# spec/models/contact_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Contact do
  it "persists a normalized synthetic contact relationship" do
    contact = create(:contact, email: "  MORGAN@EXAMPLE.TEST ", first_name: " Morgan ", last_name: " Reyes ")

    expect(contact).to have_attributes(email: "morgan@example.test", first_name: "Morgan", last_name: "Reyes")
    expect(contact.full_name).to eq("Morgan Reyes")
    expect(contact.account.contacts).to contain_exactly(contact)
  end

  it "requires bounded identity fields and an allowlisted relationship role" do
    contact = build(
      :contact,
      email: "not-an-email",
      first_name: "",
      job_title: "x" * 81,
      last_name: "",
      relationship_role: "Buyer stage"
    )

    expect(contact).not_to be_valid
    expect(contact.errors).to include(:email, :first_name, :job_title, :last_name, :relationship_role)
  end

  it "requires a unique normalized email" do
    create(:contact, email: "morgan@example.test")

    expect(build(:contact, email: "MORGAN@example.test")).not_to be_valid
  end

  it "exposes only safe Ransack fields and relationships" do
    expect(described_class.ransackable_associations).to eq([ "account" ])
    expect(described_class.ransackable_attributes).to include("email", "first_name", "job_title", "last_name")
  end
end
