require 'rails_helper'

RSpec.describe "Messages", type: :request do
  let(:business1) { Business.create!(name: "Business 1", timezone: "UTC") }
  let(:business2) { Business.create!(name: "Business 2", timezone: "UTC") }
  let(:user1) { User.create!(email: "user1@example.com", password: "password123", role: :admin, business: business1) }
  let(:user2) { User.create!(email: "user2@example.com", password: "password123", role: :admin, business: business2) }
  let(:customer1) { Customer.create!(first_name: "John", last_name: "Doe", phone: "555-1234", email: "john@example.com", business: business1) }
  let(:customer2) { Customer.create!(first_name: "Jane", last_name: "Smith", phone: "555-5678", email: "jane@example.com", business: business2) }
  let!(:message1) { Message.create!(customer: customer1, body: "Hello from customer 1", direction: :inbound, status: :received, business: business1) }
  let!(:message2) { Message.create!(customer: customer2, body: "Hello from customer 2", direction: :inbound, status: :received, business: business2) }

  describe "GET /messages" do
    context "when user is not authenticated" do
      it "redirects to sign in page" do
        get messages_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is authenticated" do
      before do
        sign_in user1
      end

      it "returns http success" do
        get messages_path
        expect(response).to have_http_status(:success)
      end

      it "only shows messages from current tenant" do
        get messages_path
        expect(response.body).to include("Hello from customer 1")
        expect(response.body).not_to include("Hello from customer 2")
      end
    end
  end

  describe "GET /messages/:id" do
    context "when user is authenticated" do
      before do
        sign_in user1
      end

      it "shows message from same tenant" do
        get message_path(message1)
        expect(response).to have_http_status(:success)
      end

      it "does not allow access to message from different tenant" do
        get message_path(message2)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
