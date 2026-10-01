# spec/services/showcase/bulk_regions_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Showcase::BulkRegions do
  let(:admin) { create(:admin_user) }
  let(:account) { create(:account) }

  it "previews and durably processes partial success without replaying mutations" do
    denied = create(:account, status: "trial")
    unchanged = create(:account, region: "East")
    stale = create(:account)
    batch = described_class.preview(admin_user: admin, ids: [ account.id, denied.id, unchanged.id, stale.id, 999_999 ], region: "East")
    expect(batch.selection.pluck("reason")).to eq(%w[eligible unauthorized unchanged eligible missing])
    expect(account.reload.region).to eq("Central")
    stale.update!(name: "Updated after preview")
    expect { described_class.confirm(admin_user: admin, id: batch.id) }.to have_enqueued_job(BulkRegionJob).with(batch.id)
    2.times { described_class.perform(batch.id) }
    expect(batch.reload.results.values).to eq(%w[updated unauthorized unchanged conflict missing])
    expect(batch.state).to eq("completed")
    expect(batch.progress).to eq(100)
    expect(account.reload.lock_version).to eq(1)
    expect(account.region).to eq("East")
  end

  it "resumes after an interrupted job and rechecks current permission" do
    second = create(:account)
    batch = described_class.preview(admin_user: admin, ids: [ account.id, second.id ], region: "East")
    described_class.confirm(admin_user: admin, id: batch.id)
    allow(described_class).to receive(:apply).and_call_original
    allow(described_class).to receive(:apply).with(anything, hash_including("id" => second.id)).and_raise(IOError, "worker interrupted")
    expect { described_class.perform(batch.id) }.to raise_error(IOError)
    expect(batch.reload.results).to eq(account.id.to_s => "updated")
    second.update!(status: "trial")
    allow(described_class).to receive(:apply).and_call_original
    described_class.perform(batch.id)
    expect(batch.reload.results).to eq(account.id.to_s => "updated", second.id.to_s => "unauthorized")
    expect(account.reload.lock_version).to eq(1)
  end

  it "requires a bounded selection, authenticated owner and explicit confirmation" do
    expect { described_class.preview(admin_user: nil, ids: [ account.id ], region: "East") }.to raise_error(described_class::Rejected)
    [ [], [ "bad" ], Array.new(26, account.id) ].each do |ids|
      expect { described_class.preview(admin_user: admin, ids:, region: "East") }.to raise_error(described_class::Rejected)
    end
    expect { described_class.preview(admin_user: admin, ids: [ account.id ], region: "Moon") }.to raise_error(described_class::Rejected)
    batch = described_class.preview(admin_user: admin, ids: [ account.id ], region: "East")
    described_class.perform(batch.id)
    expect(batch.reload.results).to eq({})
    expect { described_class.confirm(admin_user: create(:admin_user), id: batch.id) }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
