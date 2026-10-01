# spec/services/showcase/reversible_regions_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Showcase::ReversibleRegions do
  let(:admin) { create(:admin_user) }
  let(:account) { create(:account, status: "active", region: "Central") }
  let(:key) { SecureRandom.uuid }
  let(:now) { Time.current }

  def change
    described_class.change(admin_user: admin, account:, value: "East", request_key: key, expected_version: 0, now:)
  end

  it "atomically changes and appends a new audit command for idempotent undo" do
    receipt = change
    expect(change).to eq(receipt)
    expect(account.reload.region).to eq("East")
    expect(receipt.events.pluck(:kind)).to eq([ "change" ])
    described_class.undo(admin_user: admin, id: receipt.id, now: now + 1.second)
    described_class.undo(admin_user: admin, id: receipt.id, now: now + 1.hour)
    expect(account.reload.region).to eq("Central")
    expect(receipt.events.order(:id).pluck(:kind)).to eq(%w[change undo])
    expect { receipt.events.first.update!(from_value: "West") }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end

  it "rejects expiry at the exact server boundary without changing records" do
    receipt = change
    expect { described_class.undo(admin_user: admin, id: receipt.id, now: receipt.expires_at) }.to raise_error(described_class::Rejected, /expired/)
    expect(account.reload.region).to eq("East")
    expect(receipt.events.count).to eq(1)
  end

  it "refuses to overwrite a concurrent edit or lost permission" do
    receipt = change
    account.update!(name: "Concurrently renamed")
    expect { described_class.undo(admin_user: admin, id: receipt.id, now:) }.to raise_error(described_class::Rejected, /account changed/)
    account.update!(status: "trial")
    expect { described_class.undo(admin_user: admin, id: receipt.id, now:) }.to raise_error(described_class::Rejected, /authorization changed/)
    expect { described_class.undo(admin_user: create(:admin_user), id: receipt.id, now:) }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "rejects malformed, stale, unauthorized and reused command inputs" do
    expect { described_class.change(admin_user: nil, account:, value: "East", request_key: key, expected_version: 0) }.to raise_error(described_class::Rejected)
    expect { described_class.change(admin_user: admin, account:, value: "East", request_key: "bad", expected_version: 0) }.to raise_error(described_class::Rejected)
    expect { described_class.change(admin_user: admin, account:, value: "Other", request_key: key, expected_version: 0) }.to raise_error(described_class::Rejected)
    expect { described_class.change(admin_user: admin, account:, value: "East", request_key: key, expected_version: "bad") }.to raise_error(described_class::Rejected)
    expect { described_class.change(admin_user: admin, account:, value: "East", request_key: key, expected_version: 99) }.to raise_error(described_class::Rejected)
    expect { described_class.change(admin_user: admin, account:, value: "Central", request_key: key, expected_version: 0) }.to raise_error(described_class::Rejected)
    change
    expect { described_class.change(admin_user: admin, account:, value: "West", request_key: key, expected_version: 0) }.to raise_error(described_class::Rejected)
    expect { described_class.undo(admin_user: nil, id: 1) }.to raise_error(described_class::Rejected)
  end
end
