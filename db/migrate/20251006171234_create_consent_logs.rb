class CreateConsentLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :consent_logs, id: :uuid do |t|
      t.references :customer, null: false, foreign_key: true, type: :uuid
      t.text :consent_text
      t.datetime :consented_at

      t.timestamps
    end

    add_index :consent_logs, :consented_at
  end
end
