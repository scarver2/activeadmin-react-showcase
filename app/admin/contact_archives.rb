# app/admin/contact_archives.rb
# frozen_string_literal: true

ActiveAdmin.register_page "Contact Archives" do
  menu parent: "Data & Workflows", priority: 8

  content title: "ABBU Contact Archive Inspector" do
    inspector = ContactArchives::SyntheticInspector.new
    panel "Synthetic, read-only laboratory" do
      para "Three fictional contacts from a committed legacy plist ABBU bundle. No upload, live Apple Contacts access, CRM import or archive writer is enabled."
      para "Inspection and downloads never create or modify CRM records. Shared email/phone values are evidence, not proof that two people are the same."
      para "Parser: #{inspector.archive.sqlite? ? 'SQLite' : 'Legacy plist'} · Contacts: #{inspector.contacts.size} · Diagnostics: #{inspector.archive.diagnostics.size}"
      para "abbu #{Abbu::VERSION} · Exact source #{ContactArchives::SyntheticInspector::REVISION}"
      ul do
        ContactArchives::SyntheticInspector::EXPORTERS.each_key do |format|
          li link_to("Download synthetic #{format == 'vcf' ? 'vCard' : format.upcase}", admin_contact_archive_export_path(format_name: format))
        end
      end
    end
    inspector.contacts.each do |contact|
      panel contact.full_name do
        attributes_table_for contact do
          row(:nickname)
          row(:company)
          row(:job_title)
          row(:department)
          row("Contact image") { contact.image_path ? "Available" : "Not present in this fixture" }
        end
        %i[emails phones addresses urls related_names social_profiles notes].each do |field|
          h3 field.to_s.humanize
          pre JSON.pretty_generate(contact.public_send(field)), style: "white-space: pre-wrap; overflow-wrap: anywhere;"
        end
      end
    end
    panel "Exact shared-value evidence" do
      inspector.evidence.each do |candidate|
        h3 "#{candidate.fetch(:left)} / #{candidate.fetch(:right)}"
        pre JSON.pretty_generate(candidate.fetch(:signals)), style: "white-space: pre-wrap; overflow-wrap: anywhere;"
      end
      para "No automatic merge, probability claim or canonical identity is produced. Reviewer-controlled reconciliation is a later slice."
    end
    panel "Developer Notes" do
      para "ABBU plist fields → abbu normalized Ruby contacts → read-only Rails presentation. The same normalized contacts feed the upstream CSV, JSON and vCard exporters."
      para "First / Last → first_name / last_name; Email.values → emails; Phone.values → phones; Address.values → addresses; Organization → company; Note → notes."
      para "No JavaScript is required. Upload validation, transactional import, reconciliation choices and CRM-to-ABBU round-trip acceptance remain outstanding under #152."
    end
  end
end
