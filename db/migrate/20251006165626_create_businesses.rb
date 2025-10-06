class CreateBusinesses < ActiveRecord::Migration[8.0]
  def change
    enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')

    create_table :businesses, id: :uuid do |t|
      t.string :name, null: false
      t.string :timezone, null: false

      t.timestamps
    end

    add_index :businesses, :name
  end
end
