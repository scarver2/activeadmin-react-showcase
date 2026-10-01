# app/models/saved_view.rb
# frozen_string_literal: true

# Personal account-view definitions are versioned proposals, never query code.
class SavedView < ApplicationRecord
  COLUMNS = %w[name plan region status activeUsers revenueCents].freeze
  DENSITIES = %w[compact comfortable spacious].freeze
  GROUPS = %w[none plan region status].freeze
  DEFAULT_DEFINITION = {
    "schema" => 1, "query" => "", "plan" => "", "status" => "",
    "sort" => "name", "direction" => "asc", "per_page" => 5,
    "columns" => %w[name plan region status], "group" => "none", "density" => "comfortable"
  }.freeze

  belongs_to :admin_user
  validates :name, presence: true, length: { maximum: 80 }, uniqueness: { scope: :admin_user_id }
  validate :valid_definition

  def normalized_definition
    value = definition
    raise ArgumentError, "This view uses an unsupported schema. Edit and save a current definition." unless value.is_a?(Hash) && value["schema"] == 1
    raise ArgumentError, "Unknown saved-view fields" unless (value.keys - DEFAULT_DEFINITION.keys).empty?
    normalized = DEFAULT_DEFINITION.merge(value)
    raise ArgumentError, "Unsupported columns" unless normalized["columns"].is_a?(Array) && normalized["columns"].include?("name") && normalized["columns"].uniq == normalized["columns"] && (normalized["columns"] - COLUMNS).empty?
    raise ArgumentError, "Unsupported grouping" unless GROUPS.include?(normalized["group"])
    raise ArgumentError, "Unsupported density" unless DENSITIES.include?(normalized["density"])
    Showcase::AccountExplorer.new(**normalized.slice("query", "plan", "status", "sort", "direction", "per_page").symbolize_keys)
    normalized
  end

  def account_data(page: 1)
    values = normalized_definition.slice("query", "plan", "status", "sort", "direction", "per_page")
    Showcase::AccountExplorer.new(**values.symbolize_keys, page:).as_json
  end

  def make_default!
    admin_user.with_lock do
      admin_user.saved_views.where(default_view: true).where.not(id:).update_all(default_view: false, updated_at: Time.current)
      update!(default_view: true)
    end
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[name favorite default_view created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end

  private

  def valid_definition
    normalized_definition
  rescue ArgumentError => error
    errors.add(:definition, error.message)
  end
end
