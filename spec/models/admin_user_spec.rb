# spec/models/admin_user_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdminUser do
  it "builds a valid administrator" do
    expect(build(:admin_user)).to be_valid
  end

  it "accepts only supported visual theme preferences" do
    expect(build(:admin_user, theme_preference: "v3_texas")).to be_valid
    expect(build(:admin_user, theme_preference: "invented")).not_to be_valid
  end
end
