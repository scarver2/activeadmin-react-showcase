# spec/services/showcase/global_search_index_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Showcase::GlobalSearchIndex do
  it "restores missing searchable documents from authoritative Rails records" do
    account = create(:account, name: "Cedar Services")
    article = create(:showcase_article, title: "Cedar Field Guide")
    AccountDocument.delete_all
    ShowcaseArticleDocument.delete_all
    clear_fts_tables

    expect(Account.search("cedar").results).to be_empty
    expect(ShowcaseArticle.search("cedar").results).to be_empty

    described_class.rebuild!

    expect(Account.search("cedar").results).to contain_exactly(account)
    expect(ShowcaseArticle.search("cedar").results).to contain_exactly(article)
  end

  it "removes orphaned documents while rebuilding in bounded batches" do
    account = create(:account, name: "Cedar Services")
    AccountDocument.create!(account_id: "missing")
    ActiveRecord::Base.connection.execute(
      "INSERT INTO account_documents_fts (rowid, name) " \
        "VALUES ((SELECT rowid FROM account_documents WHERE account_id = 'missing'), 'Cedar Orphan')"
    )

    described_class.rebuild!

    expect(AccountDocument.pluck(:account_id)).to contain_exactly(account.id.to_s)
    expect(Account.search("orphan").results).to be_empty
  end

  def clear_fts_tables
    connection = ActiveRecord::Base.connection
    connection.execute("DELETE FROM account_documents_fts")
    connection.execute("DELETE FROM showcase_article_documents_fts")
  end
end
