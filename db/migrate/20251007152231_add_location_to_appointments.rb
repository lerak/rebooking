class AddLocationToAppointments < ActiveRecord::Migration[8.0]
  def change
    add_column :appointments, :location, :string
  end
end
