class CreateImages < ActiveRecord::Migration[7.0]
  def change
   create_table :images, id: :bigserial do |t|
     t.uuid :object_id
     t.string :image_path, null: false, unique: true
     t.integer :updated_by
     t.timestamps
 
     t.foreign_key :image_objects, column: :object_id, on_delete: :cascade
   end
 
    execute <<-SQL
      CREATE SEQUENCE images_id_seq;
      ALTER TABLE images ALTER COLUMN id SET DEFAULT nextval('images_id_seq');
    SQL
  end
 end
 