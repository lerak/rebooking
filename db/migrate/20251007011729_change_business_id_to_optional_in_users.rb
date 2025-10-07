class ChangeBusinessIdToOptionalInUsers < ActiveRecord::Migration[8.0]
  def change
    change_column_null :users, :business_id, true
  end
end
