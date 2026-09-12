# spec/services/showcase/global_search_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Showcase::GlobalSearch do
  subject(:results) { described_class.new(admin_user: admin, query:).as_json.fetch(:results) }

  let(:admin) { create(:admin_user) }
  let(:query) { "cedar" }

  it "ranks exact, prefix, and substring matches deterministically across durable resources" do
    substring = create(:account, name: "North Cedar Services")
    prefix_article = create(:showcase_article, title: "Cedar field guide")
    exact = create(:account, name: "Cedar")
    create(:showcase_article, title: "Unrelated", summary: "Not a match")

    expect(results.pluck(:id)).to eq([ "account-#{exact.id}", "article-#{prefix_article.id}", "account-#{substring.id}" ])
    expect(results.first).to include(
      description: "Growth · Central · Active",
      kind: "Account",
      label: "Cedar",
      url: Rails.application.routes.url_helpers.admin_account_path(exact)
    )
    expect(results.second).to include(
      kind: "Article",
      url: Rails.application.routes.url_helpers.admin_showcase_article_path(prefix_article)
    )
  end

  it "uses resource, label, and record ID to make equal-ranked ties stable" do
    article = create(:showcase_article, title: "Cedar Blue")
    account = create(:account, name: "Cedar Blue")
    later_account = create(:account, name: "Cedar Bluebonnet")

    expect(results.pluck(:id)).to eq([ "account-#{account.id}", "account-#{later_account.id}", "article-#{article.id}" ])
  end

  it "searches article summaries and supplies a durable default description" do
    summary_article = create(:showcase_article, summary: "Cedar migration notes", title: "Operations notes")
    article = create(:showcase_article, summary: "", title: "Cedar operations guide")

    expect(results).to include(include(kind: "Article", label: summary_article.title))
    expect(results).to include(include(kind: "Article", description: "Showcase article", label: "Cedar operations guide"))
  end

  it "returns empty results for blank and literal wildcard-only queries" do
    create(:account, name: "Cedar")

    expect(described_class.new(admin_user: admin, query: "  ").as_json).to eq(query: "", results: [])
    expect(described_class.new(admin_user: admin, query: "%_").as_json.fetch(:results)).to be_empty
  end

  it "caps the globally ranked response" do
    10.times { |number| create(:showcase_article, title: format("Match %02d", number)) }

    capped = described_class.new(admin_user: admin, query: "match").as_json.fetch(:results)

    expect(capped.length).to eq(described_class::MAXIMUM_RESULTS)
    expect(capped.pluck(:label)).to eq((0..7).map { |number| format("Match %02d", number) })
  end

  it "requires a persisted administrator and bounded text input" do
    expect { described_class.new(admin_user: nil, query:) }.to raise_error(described_class::Unauthorized)
    expect { described_class.new(admin_user: build(:admin_user), query:) }.to raise_error(described_class::Unauthorized)
    expect { described_class.new(admin_user: admin, query: [ "cedar" ]) }.to raise_error(ArgumentError, "query must be text")
    expect { described_class.new(admin_user: admin, query: "x" * 81) }.to raise_error(ArgumentError, "query must not exceed 80 characters")
  end
end
