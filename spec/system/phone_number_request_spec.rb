require 'rails_helper'

RSpec.describe 'Phone Number Request Flow', type: :system do
  let(:business) { create(:business) }
  let(:user) { create(:user, business: business, email: 'user@example.com', password: 'password123') }

  before do
    driven_by(:rack_test)
    ActsAsTenant.current_tenant = business
  end

  describe 'requesting a new phone number' do
    it 'allows user to submit a phone number request' do
      # Sign in
      visit new_user_session_path
      fill_in 'Email', with: user.email
      fill_in 'Password', with: 'password123'
      click_button 'Log in'

      # Navigate to phone numbers page
      visit settings_twilio_phone_numbers_path

      # Should see empty state
      expect(page).to have_content('No phone numbers requested yet')

      # Click to request new phone number
      click_link 'Request New Phone Number'

      # Fill in the form
      expect(page).to have_content('Request New Phone Number')
      fill_in 'Phone Number', with: '+15555551234'
      fill_in 'Location/Business Name', with: 'Downtown Office'

      # Submit the request
      expect {
        click_button 'Submit Request'
      }.to change(TwilioPhoneNumber, :count).by(1)

      # Should redirect to index with success message
      expect(page).to have_content('Phone number request submitted successfully')
      expect(page).to have_content('+15555551234')
      expect(page).to have_content('Downtown Office')
    end

    it 'displays pending status for new requests' do
      # Sign in
      visit new_user_session_path
      fill_in 'Email', with: user.email
      fill_in 'Password', with: 'password123'
      click_button 'Log in'

      # Create a phone number request
      visit new_settings_twilio_phone_number_path
      fill_in 'Phone Number', with: '+15555551234'
      fill_in 'Location/Business Name', with: 'Main Office'
      click_button 'Submit Request'

      # Should show pending status
      expect(page).to have_content('Pending')
      expect(page).to have_content('+15555551234')
    end

    it 'validates required fields' do
      # Sign in
      visit new_user_session_path
      fill_in 'Email', with: user.email
      fill_in 'Password', with: 'password123'
      click_button 'Log in'

      # Try to submit empty form
      visit new_settings_twilio_phone_number_path

      expect {
        click_button 'Submit Request'
      }.not_to change(TwilioPhoneNumber, :count)

      # Should show validation errors
      expect(page).to have_content('error')
    end

    it 'prevents duplicate phone numbers' do
      # Create existing phone number
      create(:twilio_phone_number, business: business, phone_number: '+15555551234')

      # Sign in
      visit new_user_session_path
      fill_in 'Email', with: user.email
      fill_in 'Password', with: 'password123'
      click_button 'Log in'

      # Try to request the same phone number
      visit new_settings_twilio_phone_number_path
      fill_in 'Phone Number', with: '+15555551234'
      fill_in 'Location/Business Name', with: 'Another Office'

      expect {
        click_button 'Submit Request'
      }.not_to change(TwilioPhoneNumber, :count)

      # Should show uniqueness error
      expect(page).to have_content('has already been taken')
    end
  end

  describe 'viewing phone number requests' do
    it 'displays all phone number requests for the business' do
      # Create multiple phone numbers
      phone1 = create(:twilio_phone_number, business: business, phone_number: '+15555551234', location: 'Office A', status: :pending)
      phone2 = create(:twilio_phone_number, business: business, phone_number: '+15555551235', location: 'Office B', status: :approved)
      phone3 = create(:twilio_phone_number, business: business, phone_number: '+15555551236', location: 'Office C', status: :active)

      # Sign in
      visit new_user_session_path
      fill_in 'Email', with: user.email
      fill_in 'Password', with: 'password123'
      click_button 'Log in'

      # Visit phone numbers page
      visit settings_twilio_phone_numbers_path

      # Should see all phone numbers
      expect(page).to have_content('+15555551234')
      expect(page).to have_content('Office A')
      expect(page).to have_content('Pending')

      expect(page).to have_content('+15555551235')
      expect(page).to have_content('Office B')
      expect(page).to have_content('Approved')

      expect(page).to have_content('+15555551236')
      expect(page).to have_content('Office C')
      expect(page).to have_content('Active')
    end

    it 'does not show phone numbers from other businesses' do
      other_business = create(:business)
      other_phone = create(:twilio_phone_number, business: other_business, phone_number: '+15555559999')

      # Sign in
      visit new_user_session_path
      fill_in 'Email', with: user.email
      fill_in 'Password', with: 'password123'
      click_button 'Log in'

      # Visit phone numbers page
      visit settings_twilio_phone_numbers_path

      # Should not see other business's phone number
      expect(page).not_to have_content('+15555559999')
    end
  end

  describe 'admin approval simulation' do
    it 'shows status changes after admin approval' do
      # Create a pending phone number
      phone_number = create(:twilio_phone_number, business: business, phone_number: '+15555551234', location: 'Main Office', status: :pending)

      # Sign in
      visit new_user_session_path
      fill_in 'Email', with: user.email
      fill_in 'Password', with: 'password123'
      click_button 'Log in'

      # Visit phone numbers page
      visit settings_twilio_phone_numbers_path

      # Should see pending status
      expect(page).to have_content('Pending')

      # Simulate admin approval (would normally be done via rails console)
      phone_number.approve!

      # Refresh the page
      visit settings_twilio_phone_numbers_path

      # Should now see approved status
      expect(page).to have_content('Approved')

      # Simulate activation
      phone_number.activate!

      # Refresh the page
      visit settings_twilio_phone_numbers_path

      # Should now see active status
      expect(page).to have_content('Active')
    end
  end
end
