# spec/requests/workbench_laboratory_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Workbench Laboratory" do
  it "requires administrator authentication" do
    get admin_workbench_laboratory_path
    expect(response).to redirect_to(new_admin_user_session_path)
  end

  context "with an authenticated administrator" do
    before { sign_in create(:admin_user) }

    it "renders accessible server-owned records and native resource links" do
      account = create(:account, name: "Workbench Sample")
      get admin_workbench_laboratory_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Workbench 1.3 — Heritage Laboratory", "Workbench Sample", admin_account_path(account))
      expect(response.body).to include('data-activeadmin-theme="workbench-13"')
      expect(response.body).to include(%(class="#{ActiveAdmin::Themes::Workbench13::COMPOSITION.class_for(:workspace)}"))
      expect(response.body).to include('aria-label="Account records"', 'scope="col"', 'scope="row"', 'role="status"')
      aggregate_failures "composition slots" do
        ActiveAdmin::Themes::Workbench13::COMPOSITION.slots.each_value do |css_class|
          expect(response.body).to include(css_class)
        end
      end
    end

    it "filters through a GET form without changing records" do
      create(:account, name: "Active Sample", status: "active")
      create(:account, name: "Trial Sample", status: "trial")
      expect { get admin_workbench_laboratory_path, params: { status: "trial" } }.not_to change(Account, :count)
      expect(response.body).to include("Trial Sample", "1 entry")
      expect(response.body).not_to include("Active Sample")
    end

    it "ignores unsupported filters rather than reflecting them" do
      create(:account, name: "Safe Sample")
      get admin_workbench_laboratory_path, params: { status: "<script>bad()</script>" }
      expect(response.body).to include("Safe Sample", "all statuses")
      expect(response.body).not_to include("bad()")
    end

    it "escapes record content" do
      create(:account, name: "<script>alert('record')</script>")
      get admin_workbench_laboratory_path
      expect(response.body).to include("&lt;script&gt;")
      expect(response.body).not_to include("<script>alert('record')</script>")
    end

    it "bounds the view to eight records" do
      9.times { |index| create(:account, name: "Record #{index}") }
      get admin_workbench_laboratory_path
      expect(response.body).to include("8 entries", "Record 7")
      expect(response.body).not_to include("Record 8")
    end

    it "provides an empty-state recovery action" do
      get admin_workbench_laboratory_path
      expect(response.body).to include("No accounts match this view", "Reset")
    end

    it "does not activate the experiment on other pages" do
      get admin_root_path
      expect(response.body).not_to include('data-activeadmin-theme="workbench-13"')
      expect(response.body).not_to include(ActiveAdmin::Themes::Workbench13::COMPOSITION.class_for(:workspace))
    end
  end
end
