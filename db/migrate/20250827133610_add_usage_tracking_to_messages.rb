class AddUsageTrackingToMessages < ActiveRecord::Migration[8.0]
  def change
    add_column :messages, :prompt_tokens, :integer
    add_column :messages, :completion_tokens, :integer
    add_column :messages, :total_tokens, :integer
    add_column :messages, :usage_data, :jsonb, default: {}
    
    add_index :messages, :total_tokens
    add_index :messages, :usage_data, using: :gin
  end
end
