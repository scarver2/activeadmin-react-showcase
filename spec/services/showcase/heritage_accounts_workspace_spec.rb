# spec/services/showcase/heritage_accounts_workspace_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Showcase::HeritageAccountsWorkspace do
  it "returns at most eight accounts in deterministic name and id order" do
    9.times { |index| create(:account, name: "Record #{index}") }

    expect(described_class.new.accounts.map(&:name)).to eq((0..7).map { |index| "Record #{index}" })
  end

  it "uses only an allowlisted status without changing records" do
    create(:account, name: "Active Sample", status: "active")
    trial = create(:account, name: "Trial Sample", status: "trial")

    workspace = nil
    expect { workspace = described_class.new(status: "trial") }.not_to change(Account, :count)
    expect(workspace.status).to eq("trial")
    expect(workspace.accounts).to eq([ trial ])
  end

  it "falls back to all statuses for unsupported input without reflecting it" do
    account = create(:account, name: "Safe Sample")
    workspace = described_class.new(status: "<script>bad()</script>")

    expect(workspace.status).to be_nil
    expect(workspace.accounts).to eq([ account ])
  end
end
