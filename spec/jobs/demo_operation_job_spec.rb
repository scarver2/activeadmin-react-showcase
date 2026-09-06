# spec/jobs/demo_operation_job_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe DemoOperationJob do
  around do |example|
    ClimateControl.modify(SHOWCASE_OPERATION_STEP_DELAY: "0") { example.run }
  end

  def operation_for(kind: "successful_demo")
    Operations::Create.call(admin_user: create(:admin_user), kind:)
  end

  it "performs bounded progress and completes persistently" do
    operation = operation_for

    described_class.perform_now(operation.id)

    expect(operation.reload).to have_attributes(state: "completed", progress: 100, result: /Six account/)
    expect(operation.events.pluck(:sequence)).to eq((1..7).to_a)
  end

  it "persists an expected failure as a terminal event" do
    operation = operation_for(kind: "failing_demo")

    described_class.perform_now(operation.id)

    expect(operation.reload).to have_attributes(state: "failed", error: /Demonstration failure/)
  end

  it "honors a persisted cancellation request" do
    operation = operation_for
    operation.update!(cancel_requested_at: Time.current)

    described_class.perform_now(operation.id)

    expect(operation.reload).to have_attributes(state: "cancelled")
  end

  it "ignores missing and terminal operations" do
    operation = operation_for
    operation.update!(state: "completed", progress: 100)

    expect { described_class.perform_now(-1) }.not_to raise_error
    expect { described_class.perform_now(operation.id) }.not_to change { operation.events.count }
  end

  it "persists unexpected failures and lets Solid Queue retain the failure" do
    operation = operation_for
    allow_any_instance_of(described_class).to receive(:pause).and_raise("unexpected")

    expect { described_class.perform_now(operation.id) }.to raise_error("unexpected")
    expect(operation.reload).to have_attributes(state: "failed", error: "unexpected")
  end
end
