# app/jobs/demo_operation_job.rb
# frozen_string_literal: true

class DemoOperationJob < ApplicationJob
  queue_as :default
  retry_on Operations::Claim::Busy, wait: 1.second, attempts: 5

  STEPS = [
    [ 20, "Loading authorized records" ],
    [ 45, "Computing account summaries" ],
    [ 70, "Rendering the report" ],
    [ 90, "Checking the generated artifact" ]
  ].freeze

  class ExpectedDemoFailure < StandardError; end

  def perform(operation_id)
    operation = Operation.find_by(id: operation_id)
    return unless operation
    return unless Operations::Claim.call(operation:, claim_key: job_id)

    if operation.reload.state == "queued"
      transition(operation, state: "running", progress: 5, message: "Worker started bounded demo work")
    end
    STEPS.each do |progress, message|
      return cancel(operation) if operation.reload.cancel_requested_at?
      next if progress <= operation.progress

      pause
      raise ExpectedDemoFailure, "Demonstration failure after safe cleanup" if failing_at?(operation, progress)

      transition(operation, state: "running", progress:, message:)
    end
    return cancel(operation) if operation.reload.cancel_requested_at?

    transition(
      operation,
      state: "completed",
      progress: 100,
      message: "Operation completed",
      result: "Six account summaries are ready"
    )
  rescue Operations::Claim::Busy
    raise
  rescue ExpectedDemoFailure => e
    transition(operation, state: "failed", progress: operation.progress, message: "Operation failed safely", error: e.message)
  rescue StandardError => e
    return if operation&.reload&.terminal?

    transition(operation, state: "failed", progress: operation.progress, message: "Unexpected worker failure", error: e.message)
    raise
  end

  private

  def cancel(operation)
    transition(operation, state: "cancelled", progress: operation.progress, message: "Operation cancelled")
  end

  def failing_at?(operation, progress)
    operation.kind == "failing_demo" && progress == 70
  end

  def pause
    sleep Float(ENV.fetch("SHOWCASE_OPERATION_STEP_DELAY", "0.2"))
  end

  def transition(operation, **attributes)
    Operations::Transition.call(operation:, **attributes)
  end
end
