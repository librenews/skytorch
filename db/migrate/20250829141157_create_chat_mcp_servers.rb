class CreateChatMcpServers < ActiveRecord::Migration[8.0]
  def change
    create_table :chat_mcp_servers do |t|
      t.references :chat, null: false, foreign_key: true
      t.string :name
      t.string :transport_type
      t.jsonb :config
      t.boolean :is_active

      t.timestamps
    end
  end
end
