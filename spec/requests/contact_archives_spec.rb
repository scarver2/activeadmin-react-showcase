# spec/requests/contact_archives_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Contact archive inspector" do
  let(:admin) { create(:admin_user) }

  it "requires authentication for the page and every export" do
    get admin_contact_archives_path
    expect(response).to redirect_to(new_admin_user_session_path)
    %w[csv json vcf].each do |format|
      get admin_contact_archive_export_path(format_name: format)
      expect(response).to redirect_to(new_admin_user_session_path)
    end
  end

  it "escapes fixture notes and presents a useful native inspector" do
    sign_in admin
    expect { get admin_contact_archives_path }.not_to change(Account, :count)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("ABBU Contact Archive Inspector", "Legacy plist", "Contacts: 3", "Developer Notes")
    expect(response.body).to include("&lt;script&gt;not executable&lt;/script&gt;")
    expect(response.body).not_to include("<script>not executable</script>")
  end

  it "serves authorized bounded downloads without exposing arbitrary paths" do
    sign_in admin
    %w[csv json vcf].each do |format|
      get admin_contact_archive_export_path(format_name: format), params: { path: "/etc/passwd" }
      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Disposition"]).to include("attachment", "northstar-synthetic.#{format}")
      expect(response.headers["Cache-Control"]).to include("no-store")
      expect(response.headers["X-Content-Type-Options"]).to eq("nosniff")
      expect(response.body).to include("Avery")
      expect(response.body.bytesize).to be < 30_000
    end
    get admin_contact_archive_export_path(format_name: "abbu")
    expect(response).to have_http_status(:not_found)
  end
end
