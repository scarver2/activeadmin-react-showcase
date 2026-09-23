# spec/requests/mercury_flight_laboratory_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Mercury Flight Laboratory" do
  it "requires administrator authentication" do
    get admin_mercury_flight_laboratory_path
    expect(response).to redirect_to(new_admin_user_session_path)
  end

  context "with an authenticated administrator" do
    before { sign_in create(:admin_user) }

    it "renders host-owned records through all 24 Mercury Flight roles" do
      account = create(:account, name: "Mercury Sample")
      get admin_mercury_flight_laboratory_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Mercury Flight — Heritage Laboratory", "Mercury Sample", admin_account_path(account))
      expect(response.body).to include('data-activeadmin-theme="mercury_flight"')
      expect(response.body).not_to include('data-activeadmin-theme="video_toaster_4000"', 'data-activeadmin-theme="haiku_beta6"')
      expect(response.body).to include(%(class="#{ActiveAdmin::Themes::MercuryFlight::COMPOSITION.class_for(:workspace)}"))
      expect(response.body).to include('aria-label="Account records"', 'scope="col"', 'scope="row"', 'role="status"')

      aggregate_failures "composition slots" do
        expect(ActiveAdmin::Themes::MercuryFlight::COMPOSITION.slots.length).to eq(24)
        ActiveAdmin::Themes::MercuryFlight::COMPOSITION.slots.each_value do |css_class|
          expect(response.body).to include(css_class)
        end
      end
    end

    it "filters through a GET form without changing records" do
      create(:account, name: "Active Sample", status: "active")
      create(:account, name: "Trial Sample", status: "trial")

      expect { get admin_mercury_flight_laboratory_path, params: { status: "trial" } }.not_to change(Account, :count)
      expect(response.body).to include("Trial Sample", "1 record")
      expect(response.body).not_to include("Active Sample")
    end

    it "escapes records and does not reflect unsupported filters" do
      create(:account, name: "<script>alert('record')</script>")
      get admin_mercury_flight_laboratory_path, params: { status: "<script>bad()</script>" }

      expect(response.body).to include("&lt;script&gt;", "all statuses")
      expect(response.body).not_to include("<script>alert('record')</script>", "bad()")
    end

    it "provides an empty-state recovery action" do
      get admin_mercury_flight_laboratory_path
      expect(response.body).to include("No accounts match this view", "Reset")
    end

    it "isolates Mercury Flight from preceding heritage routes" do
      get admin_video_toaster_4000_laboratory_path
      expect(response.body).to include('data-activeadmin-theme="video_toaster_4000"')
      expect(response.body).not_to include('data-activeadmin-theme="mercury_flight"')

      get admin_haiku_beta6_laboratory_path
      expect(response.body).to include('data-activeadmin-theme="haiku_beta6"')
      expect(response.body).not_to include('data-activeadmin-theme="mercury_flight"')

      get admin_root_path
      expect(response.body).not_to include('data-activeadmin-theme="mercury_flight"')
      expect(response.body).not_to include(ActiveAdmin::Themes::MercuryFlight::COMPOSITION.class_for(:workspace))
    end
  end
end
