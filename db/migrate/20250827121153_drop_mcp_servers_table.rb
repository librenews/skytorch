class DropMcpServersTable < ActiveRecord::Migration[8.0]
  def up
    drop_table :mcp_servers if table_exists?(:mcp_servers)
  end

  def down
    create_table :mcp_servers do |t|
      t.string :name
      t.string :server_type
      t.text :configuration
      t.boolean :is_active, default: true
      t.references :user, null: true, foreign_key: true

      t.timestamps
    end
  end
end
