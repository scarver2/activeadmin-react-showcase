# config/search.rb
# frozen_string_literal: true

ActiveSearch.define_index(:accounts) do
  text :name
end

ActiveSearch.define_index(:showcase_articles) do
  text :title
  text :summary
end
