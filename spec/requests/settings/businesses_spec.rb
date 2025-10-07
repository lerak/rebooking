require 'rails_helper'

RSpec.describe "Settings::Businesses", type: :request do
  let(:business) { Business.create!(name: "Test Business", timezone: "UTC") }
  let(:user_with_business) { User.create!(email: "user@example.com", password: "password123", role: :admin, business: business) }
  let(:user_without_business) { User.create!(email: "newuser@example.com", password: "password123", role: :admin, business: nil) }

  describe "GET /settings/business/edit" do
    context "when user is not authenticated" do
      it "redirects to sign in page" do
        get edit_settings_business_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user has a business" do
      before do
        sign_in user_with_business
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

    context "when user does not have a business" do
      before do
        sign_in user_without_business
      end

      it "returns http success and shows create form" do
        get edit_settings_business_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Complete Your Business Profile")
      end
    end
  end

  describe "PATCH /settings/business" do
    context "when user has an existing business" do
      before do
        sign_in user_with_business
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

      it "updates reminder_hours_before configuration" do
        patch settings_business_path, params: { business: { reminder_hours_before: 48 } }
        business.reload
        expect(business.reminder_hours_before).to eq(48)
      end

      it "rejects negative reminder_hours_before values" do
        patch settings_business_path, params: { business: { reminder_hours_before: -1 } }
        expect(response).to have_http_status(:unprocessable_entity)
        business.reload
        expect(business.reminder_hours_before).not_to eq(-1)
      end

      it "rejects zero reminder_hours_before values" do
        patch settings_business_path, params: { business: { reminder_hours_before: 0 } }
        expect(response).to have_http_status(:unprocessable_entity)
        business.reload
        expect(business.reminder_hours_before).not_to eq(0)
      end
    end

    context "when user does not have a business" do
      before do
        sign_in user_without_business
      end

      it "creates a new business for the user" do
        expect {
          patch settings_business_path, params: { business: { name: "My New Business", timezone: "UTC" } }
        }.to change(Business, :count).by(1)

        user_without_business.reload
        expect(user_without_business.business).to be_present
        expect(user_without_business.business.name).to eq("My New Business")
      end

      it "redirects to root after successful creation" do
        patch settings_business_path, params: { business: { name: "My New Business", timezone: "UTC" } }
        expect(response).to redirect_to(root_path)
      end

      it "renders edit template on validation failure" do
        patch settings_business_path, params: { business: { name: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
