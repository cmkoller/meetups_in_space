class CreateComments < ActiveRecord::Migration
  def change
    create_table :comments do |t|
      t.integer :meetup_id, null: false
      t.integer :user_id, null: false
      t.string :title
      t.text :body
      t.timestamps
    end
  end
end
