require 'rails_helper'

RSpec.describe "Tenant Isolation", type: :request do
  let!(:business1) { create(:business, name: "Business One") }
  let!(:business2) { create(:business, name: "Business Two") }

  let!(:user1) { create(:user, business: business1, email: "user1@business1.com") }
  let!(:user2) { create(:user, business: business2, email: "user2@business2.com") }

  let!(:customer1) { create(:customer, business: business1, first_name: "Customer") }
  let!(:customer2) { create(:customer, business: business2, first_name: "Customer") }

  let!(:appointment1) { create(:appointment, business: business1, customer: customer1) }
  let!(:appointment2) { create(:appointment, business: business2, customer: customer2) }

  let!(:message1) { create(:message, business: business1, customer: customer1) }
  let!(:message2) { create(:message, business: business2, customer: customer2) }

  describe "Customer isolation" do
    it "only shows customers from the current tenant" do
      login_as(user1, scope: :user)
      get customers_path
      expect(response).to have_http_status(:success)

      # Should see customer1 but not customer2
      ActsAsTenant.with_tenant(business1) do
        expect(Customer.count).to eq(1)
        expect(Customer.first).to eq(customer1)
      end
    end

    it "cannot access customers from other tenants" do
      expect {
        ActsAsTenant.with_tenant(business1) do
          Customer.find(customer2.id)
        end
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "Appointment isolation" do
    it "only shows appointments from the current tenant" do
      login_as(user1, scope: :user)
      get appointments_path
      expect(response).to have_http_status(:success)

      ActsAsTenant.with_tenant(business1) do
        expect(Appointment.count).to eq(1)
        expect(Appointment.first).to eq(appointment1)
      end
    end

    it "cannot access appointments from other tenants" do
      expect {
        ActsAsTenant.with_tenant(business1) do
          Appointment.find(appointment2.id)
        end
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "Message isolation" do
    it "only shows messages from the current tenant" do
      login_as(user1, scope: :user)
      get messages_path
      expect(response).to have_http_status(:success)

      ActsAsTenant.with_tenant(business1) do
        expect(Message.count).to eq(1)
        expect(Message.first).to eq(message1)
      end
    end

    it "cannot access messages from other tenants" do
      expect {
        ActsAsTenant.with_tenant(business1) do
          Message.find(message2.id)
        end
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "Cross-tenant contamination prevention" do
    it "user from business1 cannot see business2 data" do
      login_as(user1, scope: :user)

      get customers_path
      ActsAsTenant.with_tenant(business1) do
        expect(Customer.all).to contain_exactly(customer1)
        expect(Appointment.all).to contain_exactly(appointment1)
        expect(Message.all).to contain_exactly(message1)
      end
    end

    it "user from business2 cannot see business1 data" do
      login_as(user2, scope: :user)

      get customers_path
      ActsAsTenant.with_tenant(business2) do
        expect(Customer.all).to contain_exactly(customer2)
        expect(Appointment.all).to contain_exactly(appointment2)
        expect(Message.all).to contain_exactly(message2)
      end
    end
  end
end
