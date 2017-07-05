module MnoEnterprise::Concerns::Controllers::Jpi::V1::SubscriptionsController
  extend ActiveSupport::Concern

  SUBSCRIPTION_INCLUDES ||= [:product_instance, :product_pricing, :'product_pricing.product', :product_contract, :organization, :user, :'license_assignments.user', :'product_instance.product']

  #==================================================================
  # Instance methods
  #==================================================================
  # GET /mnoe/jpi/v1/organizations/1/subscriptions
  def index
    authorize! :manage_app_instances, parent_organization
    @subscriptions = fetch_subscriptions(parent_organization.id)
  end

  # GET /mnoe/jpi/v1/organizations/1/subscriptions/id
  def show
    authorize! :manage_app_instances, parent_organization
    @subscription = MnoEnterprise::Subscription.find_one(params[:id], SUBSCRIPTION_INCLUDES)
  end

  # POST /mnoe/jpi/v1/organizations/1/subscriptions
  def create
    authorize! :manage_app_instances, parent_organization
    subscription = MnoEnterprise::Subscription.create(subscription_create_params)

    if subscription.errors.any?
      render json: subscription.errors, status: :bad_request
    else
      MnoEnterprise::EventLogger.info('subscription_add', current_user.id, 'Subscription added', subscription)
      @subscription = subscription.load_required(SUBSCRIPTION_INCLUDES)
    end
  end

  # PUT /mnoe/jpi/v1/organizations/1/subscriptions/abc
  def update
    authorize! :manage_app_instances, parent_organization

    subscription = MnoEnterprise::Subscription.find_one(params[:id])
    return render_not_found('subscription') unless subscription
    subscription.update_attributes(subscription_update_params)

    if subscription.errors.any?
      render json: subscription.errors, status: :bad_request
    else
      MnoEnterprise::EventLogger.info('subscription_update', current_user.id, 'Subscription updated', subscription)
      @subscription = subscription.load_required(SUBSCRIPTION_INCLUDES)
    end
  end

  protected

  def subscription_create_params
    params.require(:subscription).permit(:start_date, :max_licenses, :custom_data, :product_pricing_id, :product_contract_id).merge(
      organization_id: parent_organization.id,
      user_id: current_user.id
    )
  end

  def subscription_update_params
    params.require(:subscription).permit(:start_date, :max_licenses, :custom_data, :product_pricing_id)
  end

  def fetch_subscriptions(organization_id)
    MnoEnterprise::Subscription.includes(*SUBSCRIPTION_INCLUDES).where(organization_id: organization_id)
  end

end
