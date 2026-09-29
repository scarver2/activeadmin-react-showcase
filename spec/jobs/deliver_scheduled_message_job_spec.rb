# spec/jobs/deliver_scheduled_message_job_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe DeliverScheduledMessageJob do
  it "delegates delivery for an existing scheduled message" do
    scheduled_message = create(:scheduled_message)
    allow(Conversations::DeliverScheduledMessage).to receive(:call)

    described_class.perform_now(scheduled_message.id)

    expect(Conversations::DeliverScheduledMessage).to have_received(:call).with(scheduled_message:)
  end

  it "safely ignores work deleted before execution" do
    expect { described_class.perform_now(-1) }.not_to raise_error
  end
end
