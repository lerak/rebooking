require 'rails_helper'

RSpec.describe "Appointment Management", type: :system do
  let!(:business) { create(:business) }
  let!(:user) { create(:user, business: business) }
  let!(:customer) { create(:customer, business: business, first_name: "John", last_name: "Doe") }
  let!(:appointment) { create(:appointment, business: business, customer: customer) }

  before do
    sign_in_user user
  end

  scenario "user can view appointments list" do
    visit appointments_path

    expect(page).to have_content("Appointments")
    expect(page).to have_content(customer.first_name)
  end

  scenario "user can create a new appointment" do
    visit appointments_path

    click_link "New Appointment"

    select "#{customer.first_name} #{customer.last_name}", from: "Customer"
    fill_in "Start time", with: 2.days.from_now.strftime("%Y-%m-%dT%H:%M")
    fill_in "End time", with: 2.days.from_now.advance(hours: 1).strftime("%Y-%m-%dT%H:%M")
    select "Scheduled", from: "Status"

    click_button "Create Appointment"

    expect(page).to have_content("Appointment was successfully created.")
  end

  scenario "user can edit an appointment" do
    visit appointments_path
    visit edit_appointment_path(appointment)

    select "Confirmed", from: "Status"

    click_button "Update Appointment"

    expect(page).to have_content("Appointment was successfully updated.")
  end

  scenario "user can delete an appointment", skip: "Requires JavaScript driver" do
    visit appointments_path

    accept_confirm do
      find("button[formmethod='delete']", match: :first).click
    end

    expect(page).to have_content("Appointment was successfully destroyed.")
  end

  scenario "user cannot create appointment without required fields" do
    visit appointments_path

    click_link "New Appointment"

    click_button "Create Appointment"

    expect(page).to have_content("error")
  end

  scenario "appointment end time should be after start time" do
    visit appointments_path

    click_link "New Appointment"

    select "#{customer.first_name} #{customer.last_name}", from: "Customer"
    fill_in "Start time", with: 2.days.from_now.strftime("%Y-%m-%dT%H:%M")
    fill_in "End time", with: 1.day.from_now.strftime("%Y-%m-%dT%H:%M")

    click_button "Create Appointment"

    expect(page).to have_content("error")
  end
end
