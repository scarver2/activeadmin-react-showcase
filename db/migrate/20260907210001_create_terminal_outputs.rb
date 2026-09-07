# db/migrate/20260907210001_create_terminal_outputs.rb
# frozen_string_literal: true

class CreateTerminalOutputs < ActiveRecord::Migration[8.1]
  def change
    create_table :terminal_outputs do |t|
      t.references :terminal_execution, null: false, foreign_key: true
      t.integer :sequence, null: false
      t.string :stream, null: false
      t.string :text, null: false
      t.datetime :occurred_at, null: false

      t.timestamps
    end

    add_index :terminal_outputs, %i[terminal_execution_id sequence], unique: true
    add_check_constraint :terminal_outputs,
                         "stream IN ('stdout', 'stderr', 'system')",
                         name: "terminal_outputs_valid_stream"
    add_check_constraint :terminal_outputs, "length(text) BETWEEN 1 AND 500", name: "terminal_outputs_text_length"
  end
end
