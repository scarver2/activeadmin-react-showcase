# spec/models/terminal_output_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe TerminalOutput do
  subject(:output) { build(:terminal_output) }

  it { is_expected.to belong_to(:terminal_execution) }
  it { is_expected.to validate_inclusion_of(:stream).in_array(described_class::STREAMS) }
  it { is_expected.to validate_length_of(:text).is_at_least(1).is_at_most(500) }
end
