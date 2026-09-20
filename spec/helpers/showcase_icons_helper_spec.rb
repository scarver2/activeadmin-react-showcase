# spec/helpers/showcase_icons_helper_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe ShowcaseIconsHelper do
  it "keeps every functional icon decorative" do
    described_class::ICON_NAMES.each do |name|
      expect(helper.showcase_icon(name)).to include("/showcase-icons.svg##{name}", 'aria-hidden="true"', 'focusable="false"')
    end
  end

  it "rejects unknown registry entries" do
    expect { helper.showcase_icon(:unknown) }.to raise_error(ArgumentError, "Unknown showcase icon")
  end

  it "only includes a landmark variant when explicitly requested" do
    expect(helper.showcase_icon(:dashboard, landmark: true)).to include("showcase-icon-landmark")
    expect(helper.showcase_icon(:dashboard)).not_to include("showcase-icon-landmark")
  end
end
