class CreateCustomers < ActiveRecord::Migration[8.0]
  def change
    create_table :customers, id: :uuid do |t|
      t.string :first_name
      t.string :last_name
      t.string :phone
      t.string :email
      t.references :business, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end

    add_index :customers, [:business_id, :phone], unique: true
    add_index :customers, :email
  end
end
