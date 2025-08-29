class CreateConversationStates < ActiveRecord::Migration[8.0]
  def change
    create_table :conversation_states do |t|
      t.references :chat, null: false, foreign_key: true
      t.string :status
      t.jsonb :pending_tools
      t.jsonb :missing_params
      t.jsonb :collected_params
      t.text :original_message
      t.jsonb :tool_results

      t.timestamps
    end
  end
end
