# spec/lib/activeadmin_react_showcase/version_spec.rb
# frozen_string_literal: true

require "spec_helper"
require "activeadmin_react_showcase"

RSpec.describe ActiveadminReactShowcase::VERSION do
  subject(:version) { ActiveadminReactShowcase::VERSION }

  it "is the ordinary pre-1.0 minor version for this capability" do
    expect(version).to eq("0.11.0")
    expect(version).to match(/\A0\.(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\z/)
    expect(Gem::Version.new(version).to_s).to eq(version)
  end
end
