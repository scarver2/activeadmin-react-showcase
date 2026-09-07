# app/models/terminal_output.rb
# frozen_string_literal: true

class TerminalOutput < ApplicationRecord
  STREAMS = %w[stdout stderr system].freeze

  belongs_to :terminal_execution, inverse_of: :outputs

  validates :occurred_at, presence: true
  validates :sequence, numericality: { only_integer: true, greater_than: 0 }, uniqueness: { scope: :terminal_execution_id }
  validates :stream, inclusion: { in: STREAMS }
  validates :text, length: { in: 1..500 }
end
