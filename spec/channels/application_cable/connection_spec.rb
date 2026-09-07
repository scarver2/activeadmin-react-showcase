# spec/channels/application_cable/connection_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationCable::Connection, type: :channel do
  it "identifies an authenticated administrator" do
    admin_user = create(:admin_user)
    connection = described_class.new(ActionCable.server, environment_with_warden(admin_user))

    connection.connect

    expect(connection.current_admin_user).to eq(admin_user)
  end

  it "rejects an anonymous connection" do
    connection = described_class.new(ActionCable.server, environment_with_warden(nil))

    expect { connection.connect }.to raise_error(ActionCable::Connection::Authorization::UnauthorizedError)
  end

  def environment_with_warden(admin_user)
    warden = instance_double("Warden::Proxy", user: admin_user)
    {
      "PATH_INFO" => "/cable",
      "REQUEST_METHOD" => "GET",
      "rack.input" => StringIO.new,
      "warden" => warden
    }
  end
end
