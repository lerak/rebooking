require 'rails_helper'

RSpec.describe "Customer Management", type: :system do
  let!(:business) { create(:business) }
  let!(:user) { create(:user, business: business) }
  let!(:customer) { create(:customer, business: business, first_name: "John", last_name: "Doe") }

  before do
    sign_in_user user
  end

  scenario "user can view customers list" do
    visit customers_path

    expect(page).to have_content("Customers")
    expect(page).to have_content("John Doe")
  end

  scenario "user can create a new customer" do
    visit customers_path

    click_link "New Customer"

    fill_in "First name", with: "Jane"
    fill_in "Last name", with: "Smith"
    fill_in "Email", with: "jane@example.com"
    fill_in "Phone", with: "555-1234"

    click_button "Create Customer"

    expect(page).to have_content("Customer was successfully created.")
    expect(page).to have_content("Jane Smith")
  end

  scenario "user can edit a customer" do
    visit customers_path
    visit edit_customer_path(customer)

    fill_in "First name", with: "Johnny"
    fill_in "Last name", with: "Doe"

    click_button "Update Customer"

    expect(page).to have_content("Customer was successfully updated.")
    expect(page).to have_content("Johnny Doe")
  end

  scenario "user can delete a customer", skip: "Requires JavaScript driver" do
    visit customers_path

    accept_confirm do
      find("button[formmethod='delete']", match: :first).click
    end

    expect(page).to have_content("Customer was successfully destroyed.")
    expect(page).not_to have_content("John Doe")
  end

  scenario "user cannot create customer without required fields" do
    visit customers_path

    click_link "New Customer"

    click_button "Create Customer"

    expect(page).to have_content("error")
  end
end
