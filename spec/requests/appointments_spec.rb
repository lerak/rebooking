require 'rails_helper'

RSpec.describe "Appointments", type: :request do
  let(:business1) { create(:business, name: "Business 1") }
  let(:business2) { create(:business, name: "Business 2") }
  let(:user1) { create(:user, email: "user1@example.com", business: business1) }
  let(:user2) { create(:user, email: "user2@example.com", business: business2) }
  let(:customer1) { create(:customer, first_name: "John", last_name: "Doe", email: "john@example.com", business: business1) }
  let(:customer2) { create(:customer, first_name: "Jane", last_name: "Smith", email: "jane@example.com", business: business2) }
  let!(:appointment1) { create(:appointment, customer: customer1, start_time: 1.day.from_now, end_time: 1.day.from_now + 1.hour, status: :scheduled, business: business1) }
  let!(:appointment2) { create(:appointment, customer: customer2, start_time: 2.days.from_now, end_time: 2.days.from_now + 1.hour, status: :scheduled, business: business2) }

  describe "GET /appointments" do
    context "when user is not authenticated" do
      it "redirects to sign in page" do
        get appointments_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is authenticated" do
      before do
        sign_in user1
      end

      it "returns http success" do
        get appointments_path
        expect(response).to have_http_status(:success)
      end

      it "only shows appointments from current tenant" do
        get appointments_path
        expect(response.body).to include(customer1.first_name)
        expect(response.body).not_to include(customer2.first_name)
      end
    end
  end

  describe "GET /appointments/:id" do
    context "when user is authenticated" do
      before do
        sign_in user1
      end

      it "shows appointment from same tenant" do
        get appointment_path(appointment1)
        expect(response).to have_http_status(:success)
      end

      it "does not allow access to appointment from different tenant" do
        get appointment_path(appointment2)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST /appointments" do
    context "when user is authenticated" do
      before do
        login_as(user1, scope: :user)
      end

      it "creates a new appointment for current tenant" do
        expect {
          post appointments_path, params: { appointment: { customer_id: customer1.id, start_time: 3.days.from_now, end_time: 3.days.from_now + 1.hour, status: :scheduled } }
        }.to change(Appointment, :count).by(1)

        new_appointment = Appointment.last
        expect(new_appointment.business).to eq(business1)
      end
    end
  end

  describe "PATCH /appointments/:id" do
    context "when user is authenticated" do
      before do
        sign_in user1
      end

      it "updates appointment from same tenant" do
        patch appointment_path(appointment1), params: { appointment: { status: :completed } }
        appointment1.reload
        expect(appointment1.status).to eq("completed")
      end

      it "does not allow updating appointment from different tenant" do
        patch appointment_path(appointment2), params: { appointment: { status: :completed } }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE /appointments/:id" do
    context "when user is authenticated" do
      before do
        sign_in user1
      end

      it "deletes appointment from same tenant" do
        expect {
          delete appointment_path(appointment1)
        }.to change(Appointment, :count).by(-1)
      end

      it "does not allow deleting appointment from different tenant" do
        delete appointment_path(appointment2)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
