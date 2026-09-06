# config/initializers/showcase_telemetry.rb
# frozen_string_literal: true

require Rails.root.join("app/services/showcase/telemetry/request_store")
require Rails.root.join("app/services/showcase/telemetry/request_middleware")

Rails.application.config.middleware.use Showcase::Telemetry::RequestMiddleware
