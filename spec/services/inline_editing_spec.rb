# spec/services/inline_editing_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe InlineEditing do
  let(:admin_user) { create(:admin_user) }
  let(:account) { create(:account, status: "active") }

  it "authorizes status and conditionally authorizes region per record" do
    policy = InlineEditing::Policy.new(admin_user:, account:)
    expect(policy.permitted?("status")).to be(true)
    expect(policy.permitted?("region")).to be(true)
    expect(policy.permitted?("plan")).to be(false)
    account.update!(status: "trial")
    expect(InlineEditing::Policy.new(admin_user:, account:).permitted?("region")).to be(false)
    expect(InlineEditing::Policy.new(admin_user: nil, account:).permitted?("status")).to be(false)
  end

  it "validates, persists, locks, and serializes canonical values" do
    original_lock = account.lock_version
    result = InlineEditing::Update.call(admin_user:, account:, field: "region", value: "West", expected_lock_version: original_lock)
    expect(result.reload).to have_attributes(region: "West", lock_version: original_lock + 1)
    expect(InlineEditing::Serializer.new(result).as_json).to include(region: "West", lockVersion: original_lock + 1)
  end

  it "rejects forbidden, invalid, malformed-lock, and stale writes" do
    expect { InlineEditing::Update.call(admin_user:, account:, field: "plan", value: "Starter", expected_lock_version: 0) }.to raise_error(InlineEditing::Update::Forbidden)
    expect { InlineEditing::Update.call(admin_user:, account:, field: "region", value: "Moon", expected_lock_version: 0) }.to raise_error(ActiveRecord::RecordInvalid)
    expect { InlineEditing::Update.call(admin_user:, account:, field: "region", value: "West", expected_lock_version: "bad") }.to raise_error(ActiveRecord::RecordInvalid)
    stale_lock = account.lock_version
    account.update!(region: "East")
    expect { InlineEditing::Update.call(admin_user:, account:, field: "region", value: "West", expected_lock_version: stale_lock) }.to raise_error(InlineEditing::Update::StaleWrite)
    expect(account.region).to eq("East")
  end
end
