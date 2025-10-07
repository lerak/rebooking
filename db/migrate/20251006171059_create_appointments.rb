class CreateAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :appointments, id: :uuid do |t|
      t.references :customer, null: false, foreign_key: true, type: :uuid
      t.datetime :start_time
      t.datetime :end_time
      t.integer :status
      t.references :business, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end

    add_index :appointments, [:business_id, :start_time]
    add_index :appointments, :status
  end
end
