# config/initializers/showcase_telemetry.rb
# frozen_string_literal: true

require Rails.root.join("app/services/showcase/telemetry/request_store")
require Rails.root.join("app/services/showcase/telemetry/request_middleware")
require Rails.root.join("app/services/showcase/telemetry/cable_tracker")

Rails.application.config.middleware.use Showcase::Telemetry::RequestMiddleware
Rails.application.config.x.showcase_cable_tracker = Showcase::Telemetry::CableTracker.new
