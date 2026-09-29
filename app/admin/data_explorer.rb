# app/admin/data_explorer.rb
# frozen_string_literal: true

ActiveAdmin.register_page "Data Explorer" do
  menu label: "Account Data Explorer", parent: "Data & Reporting", priority: 2

  content title: "Server-backed Account Data Explorer" do
    if params[:composition] == "bluebonnet"
      render partial: "admin/bluebonnet_workspace"
      next
    end

    accounts = Account.order(:name).limit(5)

    panel "Demo" do
      para <<~TEXT.squish
        Sort, filter, and paginate synthetic account data through an authenticated,
        bounded Rails endpoint rendered with TanStack Table. Select an account to
        inspect Rails-authorized context without abandoning the filtered workspace.
      TEXT
      para link_to("Jump to Ruby", "#ruby-guidance") + " · " +
           link_to("Jump to JavaScript", "#javascript-guidance") + " · " +
           link_to("Jump to Architecture", "#architecture-guidance")
    end

    react_component(
      "AccountExplorer",
      props: { endpoint: admin_data_explorer_accounts_path },
      fallback: lambda {
        safe_join([
          content_tag(:p, "Accounts remain available as canonical Rails pages without JavaScript."),
          content_tag(:ul) do
            safe_join(accounts.map { |account| content_tag(:li, link_to(account.name, admin_account_path(account))) })
          end,
          link_to("Browse all Rails-owned accounts", admin_accounts_path)
        ])
      },
      class: "mt-6"
    )

    panel "Ruby", id: "ruby-guidance" do
      para <<~TEXT.squish
        Rails authenticates every request, allowlists sort and filter fields, caps pages
        and page sizes, and returns only the synthetic account contract.
      TEXT
      para link_to(
        "Read the query source",
        "https://github.com/scarver2/activeadmin-react-showcase/blob/master/app/services/showcase/account_explorer.rb"
      )
      pre code("Account.order(sort => direction, id: :asc).offset(offset).limit(per_page)")
    end

    panel "JavaScript", id: "javascript-guidance" do
      para <<~TEXT.squish
        TanStack Table owns headless table rendering. React owns transient inspector
        history and focus state. Rails remains authoritative for sorting, filtering,
        pagination, account context, actions, authorization, errors, and resource URLs.
      TEXT
      para link_to(
        "Read the component source",
        "https://github.com/scarver2/activeadmin-react-showcase/blob/master/app/frontend/components/AccountExplorer.tsx"
      )
      pre code('registerComponent("AccountExplorer", AccountExplorer)')
    end

    panel "Architecture", id: "architecture-guidance" do
      para <<~TEXT.squish
        The island never receives SQL or tenant credentials. Requests use fixed query
        fields, an eight-second timeout, and server-generated ActiveAdmin links. The
        same canonical links remain navigable without JavaScript.
      TEXT
      para link_to("Browse Rails-owned Accounts", admin_accounts_path) + " · " +
           link_to("Read the inspector guide", "https://github.com/scarver2/activeadmin-react-showcase/blob/master/docs/contextual-inspector.md") + " · " +
           link_to("Explore TanStack Table", "https://tanstack.com/table") + " · " +
           link_to("Explore activeadmin-react", "https://github.com/scarver2/activeadmin-react")
    end
  end
end
