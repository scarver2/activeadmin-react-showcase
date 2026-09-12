# db/migrate/20260907400000_create_social_graph.rb
# frozen_string_literal: true

class CreateSocialGraph < ActiveRecord::Migration[8.1]
  def change
    create_table :social_people do |table|
      table.references :admin_user, null: false, foreign_key: true
      table.string :headline, null: false
      table.string :name, null: false
      table.timestamps
      table.index %i[admin_user_id name], unique: true
    end
    create_table :social_connections do |table|
      table.references :person_a, null: false, foreign_key: { to_table: :social_people, on_delete: :cascade }
      table.references :person_b, null: false, foreign_key: { to_table: :social_people, on_delete: :cascade }
      table.timestamps
      table.index %i[person_a_id person_b_id], unique: true
      table.check_constraint "person_a_id < person_b_id", name: "social_connections_canonical_order"
    end
  end
end
