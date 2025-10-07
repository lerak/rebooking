class AddEventTypeAndMetadataToConsentLogs < ActiveRecord::Migration[8.0]
  def change
    add_column :consent_logs, :event_type, :integer, null: false, default: 0
    add_column :consent_logs, :metadata, :jsonb, default: {}

    add_index :consent_logs, :event_type
  end
end
