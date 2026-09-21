# spec/requests/amigaos_4_laboratory_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "AmigaOS 4 Laboratory" do
  it "requires administrator authentication" do
    get admin_amigaos_4_laboratory_path
    expect(response).to redirect_to(new_admin_user_session_path)
  end

  context "with an authenticated administrator" do
    before { sign_in create(:admin_user) }

    it "renders host-owned records through all 24 AmigaOS 4 roles" do
      account = create(:account, name: "ReAction Sample")
      get admin_amigaos_4_laboratory_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("AmigaOS 4 — Heritage Laboratory", "ReAction Sample", admin_account_path(account))
      expect(response.body).to include('data-activeadmin-theme="amigaos_4"')
      expect(response.body).not_to include('data-activeadmin-theme="mui"')
      expect(response.body).to include(%(class="#{ActiveAdmin::Themes::AmigaOS4::COMPOSITION.class_for(:workspace)}"))
      expect(response.body).to include('aria-label="Account records"', 'scope="col"', 'scope="row"', 'role="status"')

      aggregate_failures "composition slots" do
        expect(ActiveAdmin::Themes::AmigaOS4::COMPOSITION.slots.length).to eq(24)
        ActiveAdmin::Themes::AmigaOS4::COMPOSITION.slots.each_value do |css_class|
          expect(response.body).to include(css_class)
        end
      end
    end

    it "filters through a GET form without changing records" do
      create(:account, name: "Active Sample", status: "active")
      create(:account, name: "Trial Sample", status: "trial")

      expect { get admin_amigaos_4_laboratory_path, params: { status: "trial" } }.not_to change(Account, :count)
      expect(response.body).to include("Trial Sample", "1 record")
      expect(response.body).not_to include("Active Sample")
    end

    it "escapes records and does not reflect unsupported filters" do
      create(:account, name: "<script>alert('record')</script>")
      get admin_amigaos_4_laboratory_path, params: { status: "<script>bad()</script>" }

      expect(response.body).to include("&lt;script&gt;", "all statuses")
      expect(response.body).not_to include("<script>alert('record')</script>", "bad()")
    end

    it "provides an empty-state recovery action" do
      get admin_amigaos_4_laboratory_path
      expect(response.body).to include("No accounts match these controls", "Reset")
    end

    it "isolates AmigaOS 4 from every preceding heritage route" do
      get admin_mui_laboratory_path
      expect(response.body).to include('data-activeadmin-theme="mui"')
      expect(response.body).not_to include('data-activeadmin-theme="amigaos_4"')

      get admin_workbench_3_laboratory_path
      expect(response.body).to include('data-activeadmin-theme="workbench-3"')
      expect(response.body).not_to include('data-activeadmin-theme="amigaos_4"')

      get admin_root_path
      expect(response.body).not_to include('data-activeadmin-theme="amigaos_4"')
      expect(response.body).not_to include(ActiveAdmin::Themes::AmigaOS4::COMPOSITION.class_for(:workspace))
    end
  end
end
