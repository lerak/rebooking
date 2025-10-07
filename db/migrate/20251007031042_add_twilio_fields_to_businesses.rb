class AddTwilioFieldsToBusinesses < ActiveRecord::Migration[8.0]
  def change
    add_column :businesses, :twilio_phone_number, :string
    add_column :businesses, :reminder_hours_before, :integer, default: 24
  end
end
