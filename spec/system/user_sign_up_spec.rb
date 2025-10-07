require 'rails_helper'

RSpec.describe "User Sign Up", type: :system do
  let!(:business) { create(:business, name: "Test Business") }

  scenario "user signs up with valid credentials" do
    visit new_user_registration_path

    fill_in "Email", with: "newuser@example.com"
    fill_in "Password", with: "password123"
    fill_in "Password confirmation", with: "password123"
    select business.name, from: "Business"

    click_button "Sign up"

    expect(page).to have_content("Welcome! You have signed up successfully.")
    expect(page).to have_current_path(root_path)
  end

  scenario "user cannot sign up with invalid email" do
    visit new_user_registration_path

    fill_in "Email", with: "invalid"
    fill_in "Password", with: "password123"
    fill_in "Password confirmation", with: "password123"
    select business.name, from: "Business"

    click_button "Sign up"

    expect(page).to have_content("Email is invalid")
  end

  scenario "user cannot sign up with mismatched passwords" do
    visit new_user_registration_path

    fill_in "Email", with: "newuser@example.com"
    fill_in "Password", with: "password123"
    fill_in "Password confirmation", with: "different"
    select business.name, from: "Business"

    click_button "Sign up"

    expect(page).to have_content("Password confirmation doesn't match")
  end

  scenario "user cannot sign up without a business" do
    visit new_user_registration_path

    fill_in "Email", with: "newuser@example.com"
    fill_in "Password", with: "password123"
    fill_in "Password confirmation", with: "password123"

    click_button "Sign up"

    expect(page).to have_content("Business must exist")
  end
end
