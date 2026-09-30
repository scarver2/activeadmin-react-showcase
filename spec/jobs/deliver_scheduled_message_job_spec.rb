# spec/jobs/deliver_scheduled_message_job_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe DeliverScheduledMessageJob do
  it "delegates delivery for an existing scheduled message" do
    scheduled_message = create(:scheduled_message)
    allow(Conversations::DeliverScheduledMessage).to receive(:call)

    described_class.perform_now(scheduled_message.id, scheduled_message.schedule_revision)

    expect(Conversations::DeliverScheduledMessage).to have_received(:call).with(
      expected_revision: scheduled_message.schedule_revision,
      scheduled_message:
    )
  end

  it "safely ignores work deleted before execution" do
    expect { described_class.perform_now(-1, 0) }.not_to raise_error
  end
end
