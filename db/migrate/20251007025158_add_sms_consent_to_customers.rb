class AddSmsConsentToCustomers < ActiveRecord::Migration[8.0]
  def change
    add_column :customers, :sms_consent_status, :integer, null: false, default: 1
    add_column :customers, :opted_out_at, :datetime

    add_index :customers, :sms_consent_status
    add_index :customers, :opted_out_at
  end
end
