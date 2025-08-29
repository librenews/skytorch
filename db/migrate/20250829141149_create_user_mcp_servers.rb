class CreateUserMcpServers < ActiveRecord::Migration[8.0]
  def change
    create_table :user_mcp_servers do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.string :transport_type
      t.jsonb :config
      t.boolean :is_active

      t.timestamps
    end
  end
end
