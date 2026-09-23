# spec/requests/video_toaster_4000_laboratory_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Video Toaster 4000 Laboratory" do
  it "requires administrator authentication" do
    get admin_video_toaster_4000_laboratory_path
    expect(response).to redirect_to(new_admin_user_session_path)
  end

  context "with an authenticated administrator" do
    before { sign_in create(:admin_user) }

    it "renders host-owned records through all 24 Video Toaster 4000 roles" do
      account = create(:account, name: "Toaster Sample")
      get admin_video_toaster_4000_laboratory_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(
        "Video Toaster 4000 / LightWave — Heritage Laboratory", "Toaster Sample", admin_account_path(account)
      )
      expect(response.body).to include('data-activeadmin-theme="video_toaster_4000"')
      expect(response.body).not_to include('data-activeadmin-theme="haiku_beta6"', 'data-activeadmin-theme="aros_zune"')
      expect(response.body).to include(
        %(class="#{ActiveAdmin::Themes::VideoToaster4000::COMPOSITION.class_for(:workspace)}")
      )
      expect(response.body).to include('aria-label="Account records"', 'scope="col"', 'scope="row"', 'role="status"')

      aggregate_failures "composition slots" do
        expect(ActiveAdmin::Themes::VideoToaster4000::COMPOSITION.slots.length).to eq(24)
        ActiveAdmin::Themes::VideoToaster4000::COMPOSITION.slots.each_value do |css_class|
          expect(response.body).to include(css_class)
        end
      end
    end

    it "filters through a GET form without changing records" do
      create(:account, name: "Active Sample", status: "active")
      create(:account, name: "Trial Sample", status: "trial")

      expect { get admin_video_toaster_4000_laboratory_path, params: { status: "trial" } }.not_to change(Account, :count)
      expect(response.body).to include("Trial Sample", "1 record")
      expect(response.body).not_to include("Active Sample")
    end

    it "escapes records and does not reflect unsupported filters" do
      create(:account, name: "<script>alert('record')</script>")
      get admin_video_toaster_4000_laboratory_path, params: { status: "<script>bad()</script>" }

      expect(response.body).to include("&lt;script&gt;", "all statuses")
      expect(response.body).not_to include("<script>alert('record')</script>", "bad()")
    end

    it "provides an empty-state recovery action" do
      get admin_video_toaster_4000_laboratory_path
      expect(response.body).to include("No accounts match this view", "Reset")
    end

    it "isolates Video Toaster 4000 from preceding heritage routes" do
      get admin_haiku_beta6_laboratory_path
      expect(response.body).to include('data-activeadmin-theme="haiku_beta6"')
      expect(response.body).not_to include('data-activeadmin-theme="video_toaster_4000"')

      get admin_aros_zune_laboratory_path
      expect(response.body).to include('data-activeadmin-theme="aros_zune"')
      expect(response.body).not_to include('data-activeadmin-theme="video_toaster_4000"')

      get admin_root_path
      expect(response.body).not_to include('data-activeadmin-theme="video_toaster_4000"')
      expect(response.body).not_to include(ActiveAdmin::Themes::VideoToaster4000::COMPOSITION.class_for(:workspace))
    end
  end
end
