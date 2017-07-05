module MnoEnterprise
  class ProductPricing < BaseResource
    property :created_at, type: :time
    property :updated_at, type: :time
    property :name, type: :string
    property :description, type: :string
    property :free, type: :boolean
    property :free_trial_enabled, type: :boolean
    property :free_trial_duration, type: :integer
    property :free_trial_unit, type: :string
    property :position, type: :integer
    property :per_duration, type: :string
    property :per_unit, type: :string
    property :external_id, type: :string
    property :product_id, type: :string

    def to_audit_event
      {
        id: id,
        name: name
      }
    end
  end
end
