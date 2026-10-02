# spec/services/handoffs/concurrency_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Competing handoff commands", database_cleaner: :truncation do
  it "commits one winner when cancellation and agent advancement share a version" do
    admin = create(:admin_user)
    item = admin.handoff_items.create!(title: "Synthetic checklist", state: "agent")
    ready = Queue.new
    start = Queue.new
    allow(ActionCable.server).to receive(:broadcast)
    outcomes = %w[cancel advance].map do |action|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          copy = HandoffItem.find(item.id)
          ready << true
          start.pop
          begin
            Handoffs::Transition.call(item: copy, admin_user: admin, action:, command_id: SecureRandom.uuid, version: 0)
            :saved
          rescue Handoffs::Transition::Conflict
            :conflict
          end
        end
      end
    end
    2.times { ready.pop }
    2.times { start << true }
    expect(outcomes.map(&:value).sort).to eq(%i[conflict saved])
    expect(item.events.count).to eq(1)
    expect(item.reload.lock_version).to eq(1)
  end
end
