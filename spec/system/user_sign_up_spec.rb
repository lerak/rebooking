require 'rails_helper'

RSpec.describe "User Sign Up", type: :system do
  scenario "user signs up and completes business profile" do
    visit new_user_registration_path

    fill_in "Email", with: "newuser@example.com"
    fill_in "Password", with: "password123"
    fill_in "Password confirmation", with: "password123"

    click_button "Sign up"

    # After signup, user is redirected to complete business profile
    expect(page).to have_content("Please complete your business profile to continue.")
    expect(page).to have_content("Complete Your Business Profile")

    fill_in "Business Name", with: "My New Business"
    select "UTC", from: "Timezone"

    click_button "Create Business Profile"

    expect(page).to have_content("Business profile created successfully.")
    expect(page).to have_current_path(root_path)
  end

  scenario "user cannot sign up with invalid email" do
    visit new_user_registration_path

    fill_in "Email", with: "invalid"
    fill_in "Password", with: "password123"
    fill_in "Password confirmation", with: "password123"

    click_button "Sign up"

    expect(page).to have_content("Email is invalid")
  end

  scenario "user cannot sign up with mismatched passwords" do
    visit new_user_registration_path

    fill_in "Email", with: "newuser@example.com"
    fill_in "Password", with: "password123"
    fill_in "Password confirmation", with: "different"

    click_button "Sign up"

    expect(page).to have_content("Password confirmation doesn't match")
  end

  scenario "user without business cannot access main pages" do
    user = create(:user, email: "user@example.com", password: "password123", business: nil)

    visit new_user_session_path
    fill_in "Email", with: "user@example.com"
    fill_in "Password", with: "password123"
    click_button "Log in"

    expect(page).to have_content("Please complete your business profile to continue.")
    expect(page).to have_current_path(edit_settings_business_path)
  end
end
