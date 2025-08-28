class RemoveModelIdFromChats < ActiveRecord::Migration[8.0]
  def change
    remove_column :chats, :model_id, :string
  end
end
