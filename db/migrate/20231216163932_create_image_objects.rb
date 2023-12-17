class CreateImageObjects < ActiveRecord::Migration[7.0]
  def change
    create_table :image_objects, id: false do |t|
      t.uuid :id, default: -> { "gen_random_uuid()" }, null: false, unique: true
      t.string :name
      t.text :description
      t.string :condition3d
      t.string :created_by

      t.timestamps
    end
    
    execute <<-SQL
      CREATE SEQUENCE IF NOT EXISTS image_objects_id_seq;
      ALTER TABLE image_objects ALTER COLUMN id SET DEFAULT gen_random_uuid();
      ALTER TABLE image_objects ADD CONSTRAINT image_objects_pkey PRIMARY KEY (id);
    SQL
  end
end