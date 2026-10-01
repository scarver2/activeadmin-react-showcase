# spec/models/saved_view_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe SavedView do
  let(:admin) { create(:admin_user) }
  let(:view) { described_class.new(admin_user: admin, name: "My accounts", definition: described_class::DEFAULT_DEFINITION.deep_dup) }

  it "validates bounded, versioned definitions rather than interpreting arbitrary queries" do
    expect(view).to be_valid
    [ nil, [], { "schema" => 2 }, view.definition.merge("sql" => "anything"),
      view.definition.merge("columns" => []), view.definition.merge("columns" => %w[name name]),
      view.definition.merge("columns" => %w[name secret]), view.definition.merge("group" => "secret"),
      view.definition.merge("density" => "unknown"), view.definition.merge("sort" => "secret"),
      view.definition.merge("query" => "x" * 81) ].each do |definition|
      view.definition = definition
      expect(view).not_to be_valid
    end
  end

  it "persists personal names, resolves bounded account data and prevents lost updates" do
    view.save!
    duplicate = view.dup
    expect(duplicate).not_to be_valid
    duplicate.admin_user = create(:admin_user)
    expect(duplicate).to be_valid
    account = create(:account, name: "Saved target")
    view.update!(definition: view.definition.merge("query" => "Saved target", "columns" => %w[name region]))
    expect(view.account_data[:rows].pluck(:id)).to eq([ account.id ])
    expect { view.account_data(page: 101) }.to raise_error(ArgumentError)
    stale = described_class.find(view.id)
    view.update!(name: "Changed")
    expect { stale.update!(name: "Overwritten") }.to raise_error(ActiveRecord::StaleObjectError)
  end

  it "selects exactly one default per owner without changing another owner's default" do
    view.save!
    other = admin.saved_views.create!(name: "Other", definition: view.definition)
    outsider = create(:admin_user).saved_views.create!(name: "Outside", definition: view.definition)
    outsider.make_default!
    view.make_default!
    other.make_default!
    expect(view.reload).not_to be_default_view
    expect(other.reload).to be_default_view
    expect(outsider.reload).to be_default_view
    expect { view.update_columns(default_view: true) }.to raise_error(ActiveRecord::RecordNotUnique)
  end
end
