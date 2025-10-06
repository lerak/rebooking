require 'rails_helper'

RSpec.describe ApplicationController, type: :request do
  let(:business1) { Business.create!(name: 'Business One', timezone: 'America/New_York') }
  let(:business2) { Business.create!(name: 'Business Two', timezone: 'America/Los_Angeles') }

  describe 'tenant scoping' do
    # These tests will be more meaningful once we have actual controllers with routes
    # For now, we'll test the configuration exists

    it 'has set_current_tenant_through_filter configured' do
      # Verify that ApplicationController has the tenant filter (it's a private method)
      expect(ApplicationController.private_instance_methods).to include(:set_current_tenant)
    end

    it 'has before_action for set_current_tenant' do
      callbacks = ApplicationController._process_action_callbacks.map(&:filter)
      expect(callbacks).to include(:set_current_tenant)
    end
  end

  describe 'authentication requirement' do
    it 'requires authentication for protected routes' do
      # Verify the before_action is configured
      expect(ApplicationController._process_action_callbacks.map(&:filter)).to include(:authenticate_user!)
    end
  end
end
