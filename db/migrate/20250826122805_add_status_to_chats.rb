class AddStatusToChats < ActiveRecord::Migration[8.0]
  def change
    add_column :chats, :status, :integer, default: 0, null: false
    add_index :chats, :status
  end
end
