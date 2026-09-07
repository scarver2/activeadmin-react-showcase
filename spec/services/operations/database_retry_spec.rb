# spec/services/operations/database_retry_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Operations::DatabaseRetry do
  def busy_error
    ActiveRecord::StatementInvalid.new("busy").tap do |error|
      error.define_singleton_method(:cause) { SQLite3::BusyException.new }
    end
  end

  it "retries bounded SQLite contention and then succeeds" do
    attempts = 0
    result = described_class.call do
      attempts += 1
      raise busy_error if attempts < 3

      :success
    end

    expect(result).to eq(:success)
    expect(attempts).to eq(3)
  end

  it "raises after the contention retry bound" do
    expect do
      described_class.call { raise busy_error }
    end.to raise_error(ActiveRecord::StatementInvalid)
  end

  it "does not retry unrelated statement failures" do
    attempts = 0

    expect do
      described_class.call do
        attempts += 1
        raise ActiveRecord::StatementInvalid, "invalid SQL"
      end
    end.to raise_error(ActiveRecord::StatementInvalid, "invalid SQL")
    expect(attempts).to eq(1)
  end
end
