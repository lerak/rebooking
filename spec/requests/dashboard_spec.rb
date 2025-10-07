require 'rails_helper'

RSpec.describe "Dashboards", type: :request do
  let(:business) { create(:business, name: "Test Business") }
  let(:user) { create(:user, email: "user@example.com", business: business) }

  describe "GET /dashboard" do
    context "when user is not authenticated" do
      it "redirects to sign in page" do
        get dashboard_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is authenticated" do
      before do
        sign_in user
      end

      it "returns http success" do
        get dashboard_path
        expect(response).to have_http_status(:success)
      end

      it "includes dashboard content" do
        get dashboard_path
        expect(response.body).to include("Dashboard")
        expect(response.body).to include("Total Customers")
      end
    end
  end
end
