class ChangeDataTypeImageColumns < ActiveRecord::Migration[7.0]
  def change
   change_column :images, :id, :serial
   execute "SET enable_experimental_alter_column_type_general = true"
   change_column :images, :updated_by, :string
 end
end
