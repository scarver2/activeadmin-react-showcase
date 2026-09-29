# spec/models/scheduled_message_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe ScheduledMessage do
  let(:scheduled_message) { create(:scheduled_message) }

  it "assigns separate durable public and delivery identities" do
    expect(scheduled_message.public_id).to be_present
    expect(scheduled_message.delivery_public_id).to be_present
    expect(scheduled_message.public_id).not_to eq(scheduled_message.delivery_public_id)
  end

  it "rejects an ordinary delivered message from another conversation in Rails and the database" do
    delivered_message = create(:message)

    scheduled_message.delivered_message = delivered_message
    expect(scheduled_message).not_to be_valid
    expect do
      scheduled_message.update_columns(
        delivered_at: Time.current,
        delivered_message_id: delivered_message.id,
        state: "delivered"
      )
    end
      .to raise_error(ActiveRecord::InvalidForeignKey)
  end

  it "enforces known states and bounded message bodies at the database boundary" do
    expect { scheduled_message.update_columns(state: "invented") }
      .to raise_error(ActiveRecord::StatementInvalid)
    expect { scheduled_message.update_columns(body: "") }
      .to raise_error(ActiveRecord::StatementInvalid)
  end

  it "requires durable evidence for each terminal state" do
    expect do
      scheduled_message.update_columns(state: "delivered")
    end.to raise_error(ActiveRecord::StatementInvalid)
    expect do
      scheduled_message.update_columns(state: "cancelled")
    end.to raise_error(ActiveRecord::StatementInvalid)
    expect do
      scheduled_message.update_columns(state: "failed")
    end.to raise_error(ActiveRecord::StatementInvalid)
  end

  it "rejects terminal evidence retained by another state" do
    expect do
      scheduled_message.update_columns(
        cancelled_at: Time.current,
        failed_at: Time.current,
        failure_code: "delivery_failed",
        state: "cancelled"
      )
    end.to raise_error(ActiveRecord::StatementInvalid)
    expect { scheduled_message.update_columns(schedule_revision: -1) }
      .to raise_error(ActiveRecord::StatementInvalid)
  end
end
