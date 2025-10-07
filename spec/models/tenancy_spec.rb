require 'rails_helper'

RSpec.describe "Multi-tenant isolation", type: :model do
  let(:business1) { create(:business, name: "Business One") }
  let(:business2) { create(:business, name: "Business Two") }

  let(:user1) { create(:user, business: business1) }
  let(:user2) { create(:user, business: business2) }

  describe "Customer isolation" do
    let!(:customer1) { create(:customer, business: business1) }
    let!(:customer2) { create(:customer, business: business2) }

    it "isolates customers by tenant" do
      ActsAsTenant.current_tenant = business1
      expect(Customer.all).to include(customer1)
      expect(Customer.all).not_to include(customer2)

      ActsAsTenant.current_tenant = business2
      expect(Customer.all).to include(customer2)
      expect(Customer.all).not_to include(customer1)
    end

    it "prevents cross-tenant customer access" do
      ActsAsTenant.current_tenant = business1
      expect { business1.customers.find(customer2.id) }.to raise_error(ActiveRecord::RecordNotFound)

      ActsAsTenant.current_tenant = business2
      expect { business2.customers.find(customer1.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "Appointment isolation" do
    let!(:customer1) { create(:customer, business: business1) }
    let!(:customer2) { create(:customer, business: business2) }
    let!(:appointment1) { create(:appointment, customer: customer1, business: business1) }
    let!(:appointment2) { create(:appointment, customer: customer2, business: business2) }

    it "isolates appointments by tenant" do
      ActsAsTenant.current_tenant = business1
      expect(Appointment.all).to include(appointment1)
      expect(Appointment.all).not_to include(appointment2)

      ActsAsTenant.current_tenant = business2
      expect(Appointment.all).to include(appointment2)
      expect(Appointment.all).not_to include(appointment1)
    end

    it "prevents cross-tenant appointment access" do
      ActsAsTenant.current_tenant = business1
      expect { business1.appointments.find(appointment2.id) }.to raise_error(ActiveRecord::RecordNotFound)

      ActsAsTenant.current_tenant = business2
      expect { business2.appointments.find(appointment1.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "Message isolation" do
    let!(:customer1) { create(:customer, business: business1) }
    let!(:customer2) { create(:customer, business: business2) }
    let!(:message1) { create(:message, customer: customer1, business: business1) }
    let!(:message2) { create(:message, customer: customer2, business: business2) }

    it "isolates messages by tenant" do
      ActsAsTenant.current_tenant = business1
      expect(Message.all).to include(message1)
      expect(Message.all).not_to include(message2)

      ActsAsTenant.current_tenant = business2
      expect(Message.all).to include(message2)
      expect(Message.all).not_to include(message1)
    end

    it "prevents cross-tenant message access" do
      ActsAsTenant.current_tenant = business1
      expect { business1.messages.find(message2.id) }.to raise_error(ActiveRecord::RecordNotFound)

      ActsAsTenant.current_tenant = business2
      expect { business2.messages.find(message1.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "ConsentLog isolation" do
    let!(:customer1) { create(:customer, business: business1) }
    let!(:customer2) { create(:customer, business: business2) }
    let!(:consent_log1) { create(:consent_log, customer: customer1) }
    let!(:consent_log2) { create(:consent_log, customer: customer2) }

    it "isolates consent logs through customer association" do
      expect(customer1.consent_logs).to include(consent_log1)
      expect(customer1.consent_logs).not_to include(consent_log2)

      expect(customer2.consent_logs).to include(consent_log2)
      expect(customer2.consent_logs).not_to include(consent_log1)
    end
  end

  describe "User isolation" do
    it "associates users with correct tenant" do
      expect(user1.business).to eq(business1)
      expect(user2.business).to eq(business2)
    end

    it "prevents users from accessing other tenant's business" do
      expect(user1.business).not_to eq(business2)
      expect(user2.business).not_to eq(business1)
    end
  end

  describe "Complete isolation test" do
    let!(:customer1) { create(:customer, business: business1, first_name: "Alice") }
    let!(:customer2) { create(:customer, business: business2, first_name: "Bob") }
    let!(:appointment1) { create(:appointment, customer: customer1, business: business1) }
    let!(:appointment2) { create(:appointment, customer: customer2, business: business2) }
    let!(:message1) { create(:message, customer: customer1, business: business1) }
    let!(:message2) { create(:message, customer: customer2, business: business2) }

    it "ensures complete data isolation across all models" do
      ActsAsTenant.current_tenant = business1

      # Business 1 can only see its own data
      expect(Customer.count).to eq(1)
      expect(Customer.first.first_name).to eq("Alice")
      expect(Appointment.count).to eq(1)
      expect(Message.count).to eq(1)

      ActsAsTenant.current_tenant = business2

      # Business 2 can only see its own data
      expect(Customer.count).to eq(1)
      expect(Customer.first.first_name).to eq("Bob")
      expect(Appointment.count).to eq(1)
      expect(Message.count).to eq(1)

      ActsAsTenant.current_tenant = nil

      # Without tenant context, all data is visible (at least our test data)
      expect(Customer.count).to be >= 2
      expect(Customer.where(first_name: ["Alice", "Bob"]).count).to eq(2)
      expect(Appointment.count).to be >= 2
      expect(Message.count).to be >= 2
    end
  end
end
