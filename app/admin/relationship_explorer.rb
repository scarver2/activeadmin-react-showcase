# app/admin/relationship_explorer.rb
# frozen_string_literal: true

ActiveAdmin.register_page "Relationship Explorer" do
  menu label: "Relationship Explorer", parent: "Collaboration", priority: 2

  content title: "Account & Contact Relationship Explorer" do
    accounts = Account.includes(:contacts).order(:name).limit(6)

    panel "Demo" do
      para <<~TEXT.squish
        Search synthetic accounts and contacts, narrow the relationship set through bounded
        Rails filters, inspect account context, and follow Rails-owned record links.
      TEXT
      para link_to("Jump to Ruby", "#ruby-guidance") + " · " +
           link_to("Jump to JavaScript", "#javascript-guidance") + " · " +
           link_to("Jump to Architecture", "#architecture-guidance")
    end

    react_component(
      "RelationshipExplorer",
      props: { endpoint: admin_relationship_explorer_accounts_path },
      fallback: lambda {
        safe_join([
          content_tag(:p, "Account and contact relationships remain navigable without JavaScript."),
          content_tag(:ul) do
            safe_join(accounts.map do |account|
              names = account.contacts.sort_by(&:last_name).map(&:full_name).join(", ")
              content_tag(:li, safe_join([ link_to(account.name, admin_account_path(account)), ": #{names}" ]))
            end)
          end,
          link_to("Browse all Rails-owned contacts", admin_contacts_path)
        ])
      },
      class: "mt-6"
    )

    panel "Ruby", id: "ruby-guidance" do
      para <<~TEXT.squish
        Rails authorizes the endpoint, allowlists every query field, caps text at 80 characters
        and results at 20 accounts, and returns only synthetic relationship data and record URLs.
      TEXT
      para link_to(
        "Read the query source",
        "https://github.com/scarver2/activeadmin-react-showcase/blob/master/app/services/showcase/relationship_explorer.rb"
      )
      pre code("Account.includes(:contacts).where(plan: permitted_plan).limit(20)")
    end

    panel "JavaScript", id: "javascript-guidance" do
      para <<~TEXT.squish
        The island owns transient search, selection, loading, empty, and error states.
        Account and Contact remain ordinary Rails models; React does not persist CRM state.
      TEXT
      para link_to(
        "Read the component source",
        "https://github.com/scarver2/activeadmin-react-showcase/blob/master/app/frontend/components/RelationshipExplorer.tsx"
      )
      pre code('registerComponent("RelationshipExplorer", RelationshipExplorer)')
    end

    panel "Architecture", id: "architecture-guidance" do
      para <<~TEXT.squish
        Account and Contact are the only new durable nouns. This slice intentionally excludes
        pipelines, campaigns, activity streams, write workflows, and speculative gem APIs.
      TEXT
      para link_to("Browse Rails-owned Accounts", admin_accounts_path) + " · " +
           link_to("Browse Rails-owned Contacts", admin_contacts_path) + " · " +
           link_to("Explore activeadmin-react", "https://github.com/scarver2/activeadmin-react")
    end
  end
end
