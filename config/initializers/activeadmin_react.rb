# config/initializers/activeadmin_react.rb
# frozen_string_literal: true

local_checkout = ENV["ACTIVEADMIN_REACT_PATH"]

if local_checkout.present?
  local_lib = File.expand_path("lib", local_checkout)
  raise "ACTIVEADMIN_REACT_PATH has no lib directory: #{local_checkout}" unless Dir.exist?(local_lib)

  $LOAD_PATH.unshift(local_lib) unless $LOAD_PATH.include?(local_lib)
end

require "active_admin/react"

Rails.application.config.x.activeadmin_react_source =
  local_checkout.present? ? File.expand_path(local_checkout) : Gem.loaded_specs.fetch("activeadmin-react").full_gem_path
