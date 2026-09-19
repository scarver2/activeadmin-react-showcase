# app/admin/csv_import_workflow.rb
# frozen_string_literal: true

ActiveAdmin.register_page "CSV Import Workflow" do
  menu label: "CSV Import", parent: "Data & Workflows", priority: 5

  content title: "Safe CSV import and column mapping" do
    routes = Rails.application.routes.url_helpers
    csv_import = current_admin_user.csv_imports.find_by(token: params[:token])
    serialized = csv_import && CsvImports::Serializer.new(csv_import, include_preview: csv_import.status == "draft").as_json

    panel("Demo") { para "Upload a bounded synthetic CSV, review a sample, map allowlisted columns, explicitly confirm, and follow durable processing." }
    react_component(
      "CsvImportWorkflow",
      props: { createUrl: routes.admin_csv_import_workflow_imports_path, initialImport: serialized },
      fallback: lambda {
        parts = [
          form_with(url: routes.admin_csv_import_workflow_imports_path, method: :post, multipart: true) do |form|
            safe_join([ form.label(:source, "Synthetic CSV file"), form.file_field(:source, accept: ".csv,text/csv", required: true), form.submit("Upload and preview") ])
          end
        ]
        if csv_import&.status == "draft"
          default_mapping = { "first_name" => "first_name", "last_name" => "last_name", "email" => "email", "account" => "account" }
          parts << content_tag(:p, "#{csv_import.row_count} rows validated. The fallback expects canonical headers.")
          parts << button_to("Confirm import", routes.confirm_admin_csv_import_workflow_import_path(csv_import.token), method: :post, params: { mappings: default_mapping })
        elsif csv_import
          parts << content_tag(:p, "Status: #{csv_import.status}; #{csv_import.processed_rows}/#{csv_import.row_count} rows processed.")
        end
        safe_join(parts)
      },
      class: "mt-6"
    )
    panel("Ruby", id: "ruby-guidance") { para "CsvImports::Reader and Mapping distrust file bytes and browser mappings; ProcessCsvImportJob owns partial row processing and replay-safe markers." }
    panel("JavaScript", id: "javascript-guidance") { para "React previews bounded server output, collects mappings, requires confirmation, and recovers progress from Rails after reload." }
    panel("Architecture", id: "architecture-guidance") do
      para "Active Storage retains the bounded source, SQLite persists the workflow, Solid Queue processes it, and Solid Cable accelerates progress delivery."
      para link_to("Read the CSV import guide", "https://github.com/scarver2/activeadmin-react-showcase/blob/master/docs/csv-import.md")
    end
  end
end
