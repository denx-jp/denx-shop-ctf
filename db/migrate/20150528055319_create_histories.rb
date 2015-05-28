class CreateHistories < ActiveRecord::Migration
  def change
    create_table :histories do |t|
      t.string :user_id
      t.string :username
      t.string :item_name
      t.string :item_url
      t.string :item_image_url
      t.integer :price

      t.timestamps null: false
    end
  end
end
