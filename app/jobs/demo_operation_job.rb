# app/jobs/demo_operation_job.rb
# frozen_string_literal: true

class DemoOperationJob < ApplicationJob
  queue_as :default
  retry_on Operations::Claim::Busy, wait: Operations::Claim::LEASE + 1.second, attempts: 2

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
    lease = Operations::Claim.call(operation:)
    return unless lease

    if operation.reload.state == "queued"
      transition(operation, lease:, state: "running", progress: 5, message: "Worker started bounded demo work")
    end
    STEPS.each do |progress, message|
      return cancel(operation, lease:) if operation.reload.cancel_requested_at?
      next if progress <= operation.progress

      Operations::Claim.renew!(operation:, lease:)
      pause
      raise ExpectedDemoFailure, "Demonstration failure after safe cleanup" if failing_at?(operation, progress)

      transition(operation, lease:, state: "running", progress:, message:)
    end
    return cancel(operation, lease:) if operation.reload.cancel_requested_at?

    transition(
      operation,
      lease:,
      state: "completed",
      progress: 100,
      message: "Operation completed",
      result: "Six account summaries are ready"
    )
  rescue Operations::Claim::Busy
    raise
  rescue Operations::Claim::Stale
    nil
  rescue ExpectedDemoFailure => e
    transition(operation, lease:, state: "failed", progress: operation.progress, message: "Operation failed safely", error: e.message)
  rescue StandardError => e
    return if operation&.reload&.terminal?

    transition(operation, lease:, state: "failed", progress: operation.progress, message: "Unexpected worker failure", error: e.message)
    raise
  end

  private

  def cancel(operation, lease:)
    transition(operation, lease:, state: "cancelled", progress: operation.progress, message: "Operation cancelled")
  end

  def failing_at?(operation, progress)
    operation.kind == "failing_demo" && progress == 70
  end

  def pause
    sleep Float(ENV.fetch("SHOWCASE_OPERATION_STEP_DELAY", "0.2"))
  end

  def transition(operation, lease:, **attributes)
    Operations::Transition.call(operation:, lease:, **attributes)
  end
end
