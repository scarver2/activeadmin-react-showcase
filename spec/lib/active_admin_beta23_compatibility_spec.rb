# spec/lib/active_admin_beta23_compatibility_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "ActiveAdmin beta23 compatibility" do
  let(:active_admin_specification) { Gem.loaded_specs.fetch("activeadmin") }

  it "pins the coordinated Ruby and JavaScript release" do
    package = JSON.parse(Rails.root.join("package.json").read)

    expect(active_admin_specification.version).to eq(Gem::Version.new("4.0.0.beta23"))
    expect(package.dig("dependencies", "@activeadmin/activeadmin")).to eq("4.0.0-beta23")
  end

  it "inherits the upstream Ruby 3.3 minimum" do
    requirement = active_admin_specification.required_ruby_version

    expect(requirement).not_to be_satisfied_by(Gem::Version.new("3.2.9"))
    expect(requirement).to be_satisfied_by(Gem::Version.new("3.3.0"))
    expect(requirement).to be_satisfied_by(Gem::Version.new(RUBY_VERSION))
  end

  it "does not exercise the nested belongs_to collection-name regression" do
    nested_registrations = Rails.root.glob("app/admin/**/*.rb").select do |path|
      path.each_line.any? { |line| line.match?(/^\s*belongs_to\b/) }
    end

    expect(nested_registrations).to be_empty
  end
end
