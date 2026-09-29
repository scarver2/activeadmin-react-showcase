# spec/services/conversations/availability_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Conversations::Availability do
  it "defaults production off and development/test on" do
    ClimateControl.modify(SHOWCASE_CONVERSATIONS_ENABLED: nil) do
      allow(Rails).to receive(:env).and_return(ActiveSupport::EnvironmentInquirer.new("production"))
      expect(described_class.enabled?).to be(false)

      allow(Rails).to receive(:env).and_return(ActiveSupport::EnvironmentInquirer.new("test"))
      expect(described_class.enabled?).to be(true)
    end
  end

  it "requires an explicit true value to enable production" do
    allow(Rails).to receive(:env).and_return(ActiveSupport::EnvironmentInquirer.new("production"))

    ClimateControl.modify(SHOWCASE_CONVERSATIONS_ENABLED: "true") do
      expect(described_class.enabled?).to be(true)
    end
    ClimateControl.modify(SHOWCASE_CONVERSATIONS_ENABLED: "false") do
      expect(described_class.enabled?).to be(false)
    end
    ClimateControl.modify(SHOWCASE_CONVERSATIONS_ENABLED: "flase") do
      expect(described_class.enabled?).to be(false)
    end
    ClimateControl.modify(SHOWCASE_CONVERSATIONS_ENABLED: "yes") do
      expect(described_class.enabled?).to be(false)
    end
    ClimateControl.modify(SHOWCASE_CONVERSATIONS_ENABLED: "1") do
      expect(described_class.enabled?).to be(false)
    end
  end
end
