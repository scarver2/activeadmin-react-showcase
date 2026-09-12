# app/services/workflow/serializer.rb
# frozen_string_literal: true

module Workflow
  class Serializer
    def initialize(item)
      @item = item
    end

    def as_json(*)
      {
        id: item.id,
        title: item.title,
        context: item.context,
        state: item.state,
        position: item.position,
        moveUrl: Rails.application.routes.url_helpers.admin_workflow_item_move_path(item)
      }
    end

    private

    attr_reader :item
  end
end
