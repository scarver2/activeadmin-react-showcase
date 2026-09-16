# app/admin/showcase_locations.rb
# frozen_string_literal: true

ActiveAdmin.register ShowcaseLocation do
  menu false
  permit_params :category, :latitude, :longitude, :name, :summary
end
