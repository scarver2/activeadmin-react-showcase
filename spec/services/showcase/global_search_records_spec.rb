# spec/services/showcase/global_search_records_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Showcase::GlobalSearchRecords do
  subject(:search) { described_class.new(query:, limit: 25) }

  let(:query) { "cedar" }

  it "uses Active Search for indexed Account and ShowcaseArticle candidates" do
    account = create(:account, name: "Cedar Services")
    article = create(:showcase_article, summary: "Cedar field notes", title: "Operations")

    expect(Account.search(query).results).to contain_exactly(account)
    expect(ShowcaseArticle.search(query).results).to contain_exactly(article)
    expect(search.accounts).to contain_exactly(account)
    expect(search.articles).to contain_exactly(article)
  end

  it "uses SQLite trigram indexes for the accepted mid-token substring contract" do
    account = create(:account, name: "North Cedar Services")
    article = create(:showcase_article, summary: "Bluebonnet migration notes", title: "Operations")

    expect(Account.search("dar").results).to contain_exactly(account)
    expect(ShowcaseArticle.search("bonnet").results).to contain_exactly(article)
    expect(described_class.new(query: "dar", limit: 25).accounts).to contain_exactly(account)
    expect(described_class.new(query: "bonnet", limit: 25).articles).to contain_exactly(article)
  end

  it "preserves one- and two-character searches below SQLite's trigram floor" do
    account = create(:account, name: "Cedar Services")

    expect(Account.search("ce").results).to be_empty
    expect(described_class.new(query: "ce", limit: 25).accounts).to contain_exactly(account)
  end

  it "reindexes durable records after updates and removes destroyed records" do
    account = create(:account, name: "Cedar Services")

    account.update!(name: "Juniper Services")

    expect(Account.search("cedar").results).to be_empty
    expect(Account.search("juniper").results).to contain_exactly(account)

    account.destroy!

    expect(Account.search("juniper").results).to be_empty
  end

  it "deduplicates, orders, and bounds the application candidate set" do
    accounts = 4.times.map { |number| create(:account, name: format("Cedar %02d", number)) }

    expect(described_class.new(query:, limit: 3).accounts).to eq(accounts.first(3))
  end
end
