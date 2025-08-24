class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :bluesky_did
      t.string :bluesky_handle
      t.string :display_name
      t.string :avatar_url
      t.boolean :is_admin

      t.timestamps
    end
  end
end
