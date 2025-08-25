class AddUserReferencesToExistingTables < ActiveRecord::Migration[8.0]
  def up
    # First create a default admin user
    admin_user = User.create!(
      bluesky_did: 'did:plc:admin',
      bluesky_handle: 'admin.skytorch',
      display_name: 'SkyTorch Admin',
      is_admin: true
    )

    # Add user_id to chats table
    add_reference :chats, :user, null: false, foreign_key: true, default: admin_user.id
    
    # Update existing chats to belong to admin user
    Chat.update_all(user_id: admin_user.id)
    
    # Remove the default constraint
    change_column_default :chats, :user_id, nil

    # Add user_id to llm_providers table (optional for global providers)
    add_reference :llm_providers, :user, null: true, foreign_key: true
    
    # Set existing providers to global (user_id: nil)
    LlmProvider.update_all(user_id: nil)
  end

  def down
    remove_reference :chats, :user
    remove_reference :llm_providers, :user
    User.where(bluesky_did: 'did:plc:admin').destroy_all
  end
end
