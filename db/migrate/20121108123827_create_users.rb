class CreateUsers < ActiveRecord::Migration
  def up
    create_table :users do |t|
      t.string :instagram_token
      t.string :instagram_id
      t.string :username
      t.integer :img_total_count
      t.integer :img_make_count
      t.integer :gift
      t.timestamps
    end
  end

  def down
    drop_table :users
  end
end
