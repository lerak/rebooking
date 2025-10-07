require 'rails_helper'

RSpec.describe 'Settings::TwilioPhoneNumbers', type: :request do
  let(:business) { create(:business) }
  let(:user) { create(:user, business: business) }

  before do
    ActsAsTenant.current_tenant = business
    login_as(user, scope: :user)
  end

  describe 'GET /settings/twilio_phone_numbers' do
    context 'when authenticated' do
      it 'returns a successful response' do
        get settings_twilio_phone_numbers_path
        expect(response).to have_http_status(:success)
      end

      it 'displays all phone numbers for the business' do
        phone_number1 = create(:twilio_phone_number, business: business, phone_number: '+15555551234', location: 'Office A')
        phone_number2 = create(:twilio_phone_number, business: business, phone_number: '+15555551235', location: 'Office B')

        get settings_twilio_phone_numbers_path

        expect(response.body).to include(phone_number1.phone_number)
        expect(response.body).to include(phone_number1.location)
        expect(response.body).to include(phone_number2.phone_number)
        expect(response.body).to include(phone_number2.location)
      end

      it 'does not display phone numbers from other businesses' do
        other_business = create(:business)
        other_phone_number = create(:twilio_phone_number, business: other_business, phone_number: '+15555559999', location: 'Other Office')

        get settings_twilio_phone_numbers_path

        expect(response.body).not_to include(other_phone_number.phone_number)
      end

      it 'orders phone numbers by most recent first' do
        old_number = create(:twilio_phone_number, business: business, created_at: 2.days.ago)
        new_number = create(:twilio_phone_number, business: business, created_at: 1.day.ago)

        get settings_twilio_phone_numbers_path

        expect(response.body.index(new_number.phone_number)).to be < response.body.index(old_number.phone_number)
      end
    end

    context 'when not authenticated' do
      before do
        logout(:user)
      end

      it 'redirects to sign in page' do
        get settings_twilio_phone_numbers_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /settings/twilio_phone_numbers/new' do
    context 'when authenticated' do
      it 'returns a successful response' do
        get new_settings_twilio_phone_number_path
        expect(response).to have_http_status(:success)
      end

      it 'displays the phone number request form' do
        get new_settings_twilio_phone_number_path

        expect(response.body).to include('Request New Phone Number')
        expect(response.body).to include('phone_number')
        expect(response.body).to include('location')
      end
    end

    context 'when not authenticated' do
      before do
        logout(:user)
      end

      it 'redirects to sign in page' do
        get new_settings_twilio_phone_number_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'POST /settings/twilio_phone_numbers' do
    context 'when authenticated' do
      let(:valid_attributes) do
        {
          twilio_phone_number: {
            phone_number: '+15555551234',
            location: 'Downtown Office'
          }
        }
      end

      let(:invalid_attributes) do
        {
          twilio_phone_number: {
            phone_number: '',
            location: ''
          }
        }
      end

      context 'with valid parameters' do
        it 'creates a new phone number request' do
          expect {
            post settings_twilio_phone_numbers_path, params: valid_attributes
          }.to change(TwilioPhoneNumber, :count).by(1)
        end

        it 'associates the phone number with the current user\'s business' do
          post settings_twilio_phone_numbers_path, params: valid_attributes

          phone_number = TwilioPhoneNumber.last
          expect(phone_number.business).to eq(business)
        end

        it 'sets status to pending by default' do
          post settings_twilio_phone_numbers_path, params: valid_attributes

          phone_number = TwilioPhoneNumber.last
          expect(phone_number.status).to eq('pending')
        end

        it 'redirects to the index page' do
          post settings_twilio_phone_numbers_path, params: valid_attributes
          expect(response).to redirect_to(settings_twilio_phone_numbers_path)
        end

        it 'displays a success message' do
          post settings_twilio_phone_numbers_path, params: valid_attributes
          follow_redirect!

          expect(response.body).to include('Phone number request submitted successfully')
        end
      end

      context 'with invalid parameters' do
        it 'does not create a new phone number request' do
          expect {
            post settings_twilio_phone_numbers_path, params: invalid_attributes
          }.not_to change(TwilioPhoneNumber, :count)
        end

        it 'returns unprocessable entity status' do
          post settings_twilio_phone_numbers_path, params: invalid_attributes
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'displays error messages' do
          post settings_twilio_phone_numbers_path, params: invalid_attributes

          expect(response.body).to match(/error|prohibited/i)
        end
      end

      context 'with duplicate phone number' do
        it 'does not create a duplicate phone number' do
          create(:twilio_phone_number, business: business, phone_number: '+15555551234')

          expect {
            post settings_twilio_phone_numbers_path, params: valid_attributes
          }.not_to change(TwilioPhoneNumber, :count)
        end

        it 'displays uniqueness error' do
          create(:twilio_phone_number, business: business, phone_number: '+15555551234')

          post settings_twilio_phone_numbers_path, params: valid_attributes

          expect(response.body).to include('has already been taken')
        end
      end
    end

    context 'when not authenticated' do
      before do
        logout(:user)
      end

      it 'redirects to sign in page' do
        post settings_twilio_phone_numbers_path, params: {
          twilio_phone_number: { phone_number: '+15555551234', location: 'Office' }
        }
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'does not create a phone number request' do
        expect {
          post settings_twilio_phone_numbers_path, params: {
            twilio_phone_number: { phone_number: '+15555551234', location: 'Office' }
          }
        }.not_to change(TwilioPhoneNumber, :count)
      end
    end
  end
end
