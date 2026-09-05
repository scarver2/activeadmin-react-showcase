# spec/models/admin_user_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdminUser do
  it "builds a valid administrator" do
    expect(build(:admin_user)).to be_valid
  end
end
