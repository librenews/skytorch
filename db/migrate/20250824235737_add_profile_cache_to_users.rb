class AddProfileCacheToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :description, :text
    add_column :users, :profile_updated_at, :datetime
  end
end
