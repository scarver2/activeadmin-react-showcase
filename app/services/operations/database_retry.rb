# app/services/operations/database_retry.rb
# frozen_string_literal: true

module Operations
  class DatabaseRetry
    ATTEMPTS = 5
    BASE_DELAY = 0.01

    def self.call
      attempts = 0
      begin
        yield
      rescue ActiveRecord::StatementInvalid => e
        attempts += 1
        raise unless sqlite_busy?(e) && attempts < ATTEMPTS

        sleep(BASE_DELAY * attempts)
        retry
      end
    end

    def self.sqlite_busy?(error)
      error.cause.class.name.in?(%w[SQLite3::BusyException SQLite3::LockedException])
    end
    private_class_method :sqlite_busy?
  end
end
