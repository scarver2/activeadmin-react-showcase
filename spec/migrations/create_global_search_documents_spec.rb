# spec/migrations/create_global_search_documents_spec.rb
# frozen_string_literal: true

require "rails_helper"
require "tmpdir"
require Rails.root.join("db/migrate/20260929210000_create_account_documents")
require Rails.root.join("db/migrate/20260929210001_create_showcase_article_documents")

RSpec.describe "Global Search document migrations" do
  it "creates the indexed document and FTS5 tables and rolls them back cleanly" do
    Dir.mktmpdir do |directory|
      database_class = Class.new(ActiveRecord::Base) { self.abstract_class = true }
      database_class.define_singleton_method(:name) { "GlobalSearchMigrationRecord" }
      database_class.establish_connection(adapter: "sqlite3", database: File.join(directory, "search.sqlite3"))
      connection = database_class.connection
      migrations = [ CreateAccountDocuments.new, CreateShowcaseArticleDocuments.new ]
      migrations.each { |migration| allow(migration).to receive(:connection).and_return(connection) }

      migrations.each { |migration| migration.suppress_messages { migration.migrate(:up) } }

      expect(connection.table_exists?(:account_documents)).to be(true)
      expect(connection.table_exists?(:showcase_article_documents)).to be(true)
      expect(virtual_table_sql(connection, "account_documents_fts")).to include("tokenize='trigram'")
      expect(virtual_table_sql(connection, "showcase_article_documents_fts")).to include("tokenize='trigram'")
      expect(connection.indexes(:account_documents).sole.unique).to be(true)
      expect(connection.indexes(:showcase_article_documents).sole.unique).to be(true)

      migrations.reverse_each { |migration| migration.suppress_messages { migration.migrate(:down) } }

      expect(connection.table_exists?(:account_documents)).to be(false)
      expect(connection.table_exists?(:showcase_article_documents)).to be(false)
      expect(virtual_table_sql(connection, "account_documents_fts")).to be_nil
      expect(virtual_table_sql(connection, "showcase_article_documents_fts")).to be_nil
    ensure
      database_class&.connection_pool&.disconnect!
    end
  end

  def virtual_table_sql(connection, table_name)
    connection.select_value("SELECT sql FROM sqlite_master WHERE name = #{connection.quote(table_name)}")
  end
end
