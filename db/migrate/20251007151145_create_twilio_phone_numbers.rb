class CreateTwilioPhoneNumbers < ActiveRecord::Migration[8.0]
  def change
    create_table :twilio_phone_numbers, id: :uuid do |t|
      t.references :business, null: false, foreign_key: true, type: :uuid
      t.string :phone_number, null: false
      t.integer :status, null: false, default: 0
      t.string :location, null: false

      t.timestamps
    end

    add_index :twilio_phone_numbers, :phone_number, unique: true
    add_index :twilio_phone_numbers, [:business_id, :location]
  end
end
