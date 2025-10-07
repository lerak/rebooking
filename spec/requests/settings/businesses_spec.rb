require 'rails_helper'

RSpec.describe "Settings::Businesses", type: :request do
  let(:business) { Business.create!(name: "Test Business", timezone: "UTC") }
  let(:user) { User.create!(email: "user@example.com", password: "password123", role: :admin, business: business) }

  describe "GET /settings/business/edit" do
    context "when user is not authenticated" do
      it "redirects to sign in page" do
        get edit_settings_business_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is authenticated" do
      before do
        sign_in user
      end

      it "returns http success" do
        get edit_settings_business_path
        expect(response).to have_http_status(:success)
      end

      it "displays current business information" do
        get edit_settings_business_path
        expect(response.body).to include(business.name)
      end
    end
  end

  describe "PATCH /settings/business" do
    context "when user is authenticated" do
      before do
        sign_in user
      end

      it "updates the current user's business" do
        patch settings_business_path, params: { business: { name: "Updated Business Name", timezone: "America/New_York" } }
        business.reload
        expect(business.name).to eq("Updated Business Name")
        expect(business.timezone).to eq("America/New_York")
      end

      it "redirects to edit page after successful update" do
        patch settings_business_path, params: { business: { name: "Updated Business Name" } }
        expect(response).to redirect_to(edit_settings_business_path)
      end

      it "renders edit template on validation failure" do
        patch settings_business_path, params: { business: { name: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
