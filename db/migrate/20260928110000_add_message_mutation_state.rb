# db/migrate/20260928110000_add_message_mutation_state.rb
# frozen_string_literal: true

class AddMessageMutationState < ActiveRecord::Migration[8.1]
  def change
    add_column :chat_messages, :edited_at, :datetime
    add_column :chat_messages, :withdrawn_at, :datetime
  end
end
