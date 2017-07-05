require 'rails_helper'

module MnoEnterprise
  describe Jpi::V1::SubscriptionsController, type: :controller do
    include MnoEnterprise::TestingSupport::JpiV1TestHelper
    render_views
    routes { MnoEnterprise::Engine.routes }
    before { request.env['HTTP_ACCEPT'] = 'application/json' }
    DEPENDENCIES = [:product_instance, :product_pricing, :'product_pricing.product', :product_contract, :organization, :user, :'license_assignments.user', :'product_instance.product']

    before(:all) do
      Settings.merge!(dashboard: {provisioning: {enabled: true}})
      Rails.application.reload_routes!
    end

    # Stub controller ability
    let!(:ability) { stub_ability }
    before { allow(ability).to receive(:can?).with(any_args).and_return(true) }

    # Stub user and user call
    let!(:user) { build(:user) }
    let!(:current_user_stub) { stub_api_v2(:get, "/users/#{user.id}", user, %i(deletion_requests organizations orga_relations dashboards)) }

    # Stub organization and association
    let!(:organization) { build(:organization, orga_relations: []) }
    let!(:orga_relation) { organization.orga_relations << build(:orga_relation, user_id: user.id, organization_id: organization.id, role: 'Super Admin') }
    let!(:organization_stub) { stub_api_v2(:get, "/organizations/#{organization.id}", organization, %i(orga_relations users)) }

    describe 'GET #index' do
      let(:subscription) { build(:subscription) }

      before { stub_api_v2(:get, '/subscriptions', [subscription], DEPENDENCIES, {filter: {organization_id: organization.id}}) }
      before { sign_in user }

      subject { get :index, organization_id: organization.id }

      it_behaves_like 'jpi v1 protected action'
    end

    describe 'GET #show' do
      let(:subscription) { build(:subscription) }

      before { stub_api_v2(:get, "/subscriptions/#{subscription.id}", subscription, DEPENDENCIES) }
      before { sign_in user }

      subject { get :show, organization_id: organization.id, id: subscription.id }

      it_behaves_like 'jpi v1 protected action'
    end

    describe 'POST #create' do
      let(:subscription) { build(:subscription) }
      let(:product) { build(:product) }
      let(:pricing) { build(:product_pricing, product: product) }

      before { stub_audit_events }
      before { stub_api_v2(:post, '/subscriptions', subscription, [], {}) }
      #Reload
      before { stub_api_v2(:get, "/subscriptions/#{subscription.id}", subscription, DEPENDENCIES) }
      before { sign_in user }

      subject { post :create, organization_id: organization.id, subscription: {product_pricing_id: pricing.id} }

      it_behaves_like 'jpi v1 protected action'

      it 'passes the correct parameters' do
        expect(subject).to be_successful
        assert_requested_api_v2(:post, '/subscriptions',
                                body: {
                                  data: {
                                    type: 'subscriptions',
                                    attributes: {
                                      product_pricing_id: pricing.id,
                                      organization_id: organization.id,
                                      user_id: user.id
                                    }
                                  }
                                }.to_json)
      end
    end

    describe 'PUT #update' do
      let(:subscription) { build(:subscription) }
      let(:product) { build(:product) }
      let(:pricing) { build(:product_pricing, product: product) }

      before { stub_audit_events }
      before { stub_api_v2(:get, "/subscriptions/#{subscription.id}", subscription) }
      # Subscription Reload
      before { stub_api_v2(:get, "/subscriptions/#{subscription.id}", subscription, DEPENDENCIES) }
      before { stub_api_v2(:patch, "/subscriptions/#{subscription.id}", subscription) }
      before { sign_in user }

      subject { put :update, organization_id: organization.id, id: subscription.id, subscription: {product_pricing_id: pricing.id} }

      it_behaves_like 'jpi v1 protected action'

      it 'passes the correct parameters' do
        expect(subject).to be_successful
        assert_requested_api_v2(:patch, "/subscriptions/#{subscription.id}",
                                body: {
                                  data: {
                                    id: subscription.id,
                                    type: 'subscriptions',
                                    attributes: {
                                      product_pricing_id: pricing.id
                                    }
                                  }
                                }.to_json)
      end
    end
  end
end
