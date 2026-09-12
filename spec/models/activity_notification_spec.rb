# spec/models/activity_notification_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActivityNotification do
  subject(:notification) { build(:activity_notification) }

  it { is_expected.to belong_to(:admin_user) }
  it { is_expected.to validate_inclusion_of(:kind).in_array(described_class::KINDS) }
  it { is_expected.to validate_presence_of(:subject) }
  it { is_expected.to validate_uniqueness_of(:sequence).scoped_to(:admin_user_id) }

  it "requires a local admin deep link" do
    notification.deep_link = "https://example.test/phishing"
    expect(notification).not_to be_valid
  end

  it "changes read state idempotently" do
    notification.save!
    expect { notification.mark_read! }.to change(notification, :read_at).from(nil)
    expect { notification.mark_read! }.not_to change(notification, :updated_at)
    expect { notification.mark_unread! }.to change(notification, :read_at).to(nil)
    expect { notification.mark_unread! }.not_to change(notification, :updated_at)
  end

  it "exposes bounded Ransack fields" do
    expect(described_class.ransackable_associations).to eq([ "admin_user" ])
    expect(described_class.ransackable_attributes).to include("subject", "read_at")
  end
end
