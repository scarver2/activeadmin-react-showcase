# spec/models/daily_metric_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe DailyMetric do
  subject(:daily_metric) { build(:daily_metric) }

  it { is_expected.to belong_to(:account) }
  it { is_expected.to validate_presence_of(:recorded_on) }

  it "rejects negative metrics" do
    daily_metric.error_count = -1

    expect(daily_metric).not_to be_valid
    expect(daily_metric.errors[:error_count]).to include("must be greater than or equal to 0")
  end
end
