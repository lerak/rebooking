class AddDeliveryTrackingToMessages < ActiveRecord::Migration[8.0]
  def change
    add_column :messages, :twilio_sid, :string
    add_column :messages, :error_message, :text
    add_column :messages, :delivered_at, :datetime

    add_index :messages, :twilio_sid
  end
end
