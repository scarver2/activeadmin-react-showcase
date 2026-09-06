# spec/models/account_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Account do
  subject(:account) { build(:account) }

  it { is_expected.to have_many(:daily_metrics).dependent(:destroy) }
  it { is_expected.to validate_inclusion_of(:plan).in_array(described_class::PLANS) }
  it { is_expected.to validate_inclusion_of(:region).in_array(described_class::REGIONS) }
  it { is_expected.to validate_inclusion_of(:status).in_array(described_class::STATUSES) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_uniqueness_of(:name) }
end
