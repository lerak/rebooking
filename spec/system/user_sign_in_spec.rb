require 'rails_helper'

RSpec.describe "User Sign In", type: :system do
  let!(:business) { create(:business) }
  let!(:user) { create(:user, business: business, email: "user@example.com", password: "password123") }

  scenario "user signs in with valid credentials" do
    visit new_user_session_path

    fill_in "Email", with: "user@example.com"
    fill_in "Password", with: "password123"

    click_button "Log in"

    expect(page).to have_content("Signed in successfully.")
    expect(page).to have_current_path(root_path)
  end

  scenario "user cannot sign in with invalid email" do
    visit new_user_session_path

    fill_in "Email", with: "wrong@example.com"
    fill_in "Password", with: "password123"

    click_button "Log in"

    expect(page).to have_content("Invalid Email or password.")
  end

  scenario "user cannot sign in with invalid password" do
    visit new_user_session_path

    fill_in "Email", with: "user@example.com"
    fill_in "Password", with: "wrongpassword"

    click_button "Log in"

    expect(page).to have_content("Invalid Email or password.")
  end

  scenario "user can sign out", skip: "Requires JavaScript driver or DOM inspection" do
    # Sign in by visiting the login page
    visit new_user_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "password123"
    click_button "Log in"

    # Now sign out - button_to creates a form with a submit button
    find('input[value="Sign Out"]').click

    expect(page).to have_content("Signed out successfully.")
  end
end
