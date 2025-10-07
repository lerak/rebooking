class CreateMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :messages, id: :uuid do |t|
      t.references :customer, null: false, foreign_key: true, type: :uuid
      t.text :body
      t.integer :direction
      t.integer :status
      t.jsonb :metadata
      t.references :business, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end

    add_index :messages, [:business_id, :created_at]
    add_index :messages, :direction
    add_index :messages, :status
  end
end
