# app/admin/content_blocks.rb
# frozen_string_literal: true

ActiveAdmin.register ContentBlock do
  menu false
  permit_params :block_type, :body, :content_document_id, :position
end
