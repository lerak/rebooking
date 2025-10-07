require 'rails_helper'

RSpec.describe "Customers", type: :request do
  let(:business1) { Business.create!(name: "Business 1", timezone: "UTC") }
  let(:business2) { Business.create!(name: "Business 2", timezone: "UTC") }
  let(:user1) { User.create!(email: "user1@example.com", password: "password123", role: :admin, business: business1) }
  let(:user2) { User.create!(email: "user2@example.com", password: "password123", role: :admin, business: business2) }
  let!(:customer1) { Customer.create!(first_name: "John", last_name: "Doe", phone: "555-1234", email: "john@example.com", business: business1) }
  let!(:customer2) { Customer.create!(first_name: "Jane", last_name: "Smith", phone: "555-5678", email: "jane@example.com", business: business2) }

  describe "GET /customers" do
    context "when user is not authenticated" do
      it "redirects to sign in page" do
        get customers_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is authenticated" do
      before do
        sign_in user1
      end

      it "returns http success" do
        get customers_path
        expect(response).to have_http_status(:success)
      end

      it "only shows customers from current tenant" do
        get customers_path
        expect(response.body).to include("John")
        expect(response.body).not_to include("Jane")
      end
    end
  end

  describe "GET /customers/:id" do
    context "when user is authenticated" do
      before do
        sign_in user1
      end

      it "shows customer from same tenant" do
        get customer_path(customer1)
        expect(response).to have_http_status(:success)
      end

      it "does not allow access to customer from different tenant" do
        get customer_path(customer2)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST /customers" do
    context "when user is authenticated" do
      before do
        sign_in user1
      end

      it "creates a new customer for current tenant" do
        expect {
          post customers_path, params: { customer: { first_name: "Alice", last_name: "Johnson", phone: "555-9999", email: "alice@example.com" } }
        }.to change(Customer, :count).by(1)

        new_customer = Customer.find_by(email: "alice@example.com")
        expect(new_customer.business).to eq(business1)
      end
    end
  end

  describe "PATCH /customers/:id" do
    context "when user is authenticated" do
      before do
        sign_in user1
      end

      it "updates customer from same tenant" do
        patch customer_path(customer1), params: { customer: { first_name: "Johnny" } }
        customer1.reload
        expect(customer1.first_name).to eq("Johnny")
      end

      it "does not allow updating customer from different tenant" do
        patch customer_path(customer2), params: { customer: { first_name: "Janet" } }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE /customers/:id" do
    context "when user is authenticated" do
      before do
        sign_in user1
      end

      it "deletes customer from same tenant" do
        expect {
          delete customer_path(customer1)
        }.to change(Customer, :count).by(-1)
      end

      it "does not allow deleting customer from different tenant" do
        delete customer_path(customer2)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
