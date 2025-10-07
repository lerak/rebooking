require 'rails_helper'

RSpec.describe "Dashboard Navigation", type: :system do
  let!(:business) { create(:business) }
  let!(:user) { create(:user, business: business) }

  before do
    sign_in_user user
  end

  scenario "user can access dashboard" do
    visit root_path

    expect(page).to have_content("Dashboard")
    expect(page).to have_current_path(root_path)
  end

  scenario "user can navigate to customers page" do
    visit root_path

    click_link "Customers"

    expect(page).to have_current_path(customers_path)
    expect(page).to have_content("Customers")
  end

  scenario "user can navigate to appointments page" do
    visit root_path

    click_link "Appointments"

    expect(page).to have_current_path(appointments_path)
    expect(page).to have_content("Appointments")
  end

  scenario "user can navigate to messages page" do
    visit root_path

    click_link "Messages"

    expect(page).to have_current_path(messages_path)
    expect(page).to have_content("Messages")
  end

  scenario "user can navigate to settings page" do
    visit root_path

    click_link "Settings"

    expect(page).to have_current_path(edit_settings_business_path)
    expect(page).to have_content("Business Settings")
  end

  scenario "navigation persists across pages" do
    visit customers_path

    expect(page).to have_link("Dashboard")
    expect(page).to have_link("Customers")
    expect(page).to have_link("Appointments")
    expect(page).to have_link("Messages")
    expect(page).to have_link("Settings")
  end
end
