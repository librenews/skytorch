class AddModelIdToChats < ActiveRecord::Migration[8.0]
  def change
    add_column :chats, :model_id, :string
  end
end
