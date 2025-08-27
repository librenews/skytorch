class User < ApplicationRecord
  has_many :chats, dependent: :destroy
  has_many :providers, dependent: :destroy

  validates :bluesky_handle, presence: true, uniqueness: true
  validates :bluesky_did, presence: true, uniqueness: true
  validates :display_name, presence: true

  def has_provider?
    providers.exists?
  end

  def using_global_provider?
    !has_provider?
  end

  def default_provider
    providers.first || Provider.global_default
  end

  def profile_updated_recently?
    profile_updated_at && profile_updated_at > 1.day.ago
  end

  def needs_profile_refresh?
    !profile_updated_recently?
  end

  def avatar_display_url
    avatar_url.presence || "https://api.dicebear.com/7.x/avataaars/svg?seed=#{bluesky_handle}"
  end

  def display_name_or_handle
    display_name.presence || bluesky_handle
  end

  def profile_cache_key
    "user_profile_#{id}_#{profile_updated_at&.to_i || 0}"
  end

  def update_profile_from_api!(profile_data)
    update!(
      bluesky_handle: profile_data[:handle] || bluesky_did,
      display_name: profile_data[:display_name] || bluesky_handle,
      avatar_url: profile_data[:avatar_url],
      description: profile_data.to_json,
      profile_updated_at: Time.current
    )
  rescue => e
    Rails.logger.error "Failed to update user profile: #{e.message}"
    # Fallback to basic info if profile update fails
    # Only update fields that won't cause validation errors
    begin
      update!(
        display_name: bluesky_handle,
        profile_updated_at: Time.current
      )
    rescue => e2
      Rails.logger.error "Fallback update also failed: #{e2.message}"
      # Last resort: just update the timestamp
      update_column(:profile_updated_at, Time.current)
    end
  end

  def self.find_or_create_from_omniauth(auth_hash)
    did = auth_hash['info']['did']
    user = find_by(bluesky_did: did)
    
    unless user
      user = create!(
        bluesky_did: did,
        bluesky_handle: did,
        display_name: did.split(':').last
      )
    end
    
    user
  end

  def self.find_by_handle_or_did(identifier)
    find_by(bluesky_handle: identifier) || find_by(bluesky_did: identifier)
  end

  def to_param
    bluesky_handle
  end

  def admin?
    # Add admin logic here if needed
    false
  end

  def moderator?
    # Add moderator logic here if needed
    false
  end

  def can_edit?(resource)
    return true if admin?
    return true if resource.respond_to?(:user_id) && resource.user_id == id
    false
  end

  def can_delete?(resource)
    return true if admin?
    return true if resource.respond_to?(:user_id) && resource.user_id == id
    false
  end

  def can_view?(resource)
    return true if admin?
    return true if resource.respond_to?(:user_id) && resource.user_id == id
    false
  end

  def can_create?(resource_class)
    return true if admin?
    return true if resource_class.respond_to?(:user_required?) && !resource_class.user_required?
    true
  end

  def can_access_feature?(feature)
    return true if admin?
    # Add feature-specific logic here
    true
  end

  def subscription_status
    # Add subscription logic here if needed
    'free'
  end

  def subscription_active?
    subscription_status != 'inactive'
  end

  def usage_limits
    # Add usage limit logic here if needed
    {
      chats_per_month: 100,
      messages_per_chat: 1000,
      storage_mb: 100
    }
  end

  def usage_this_month
    # Add usage tracking logic here if needed
    {
      chats_created: chats.where('created_at >= ?', Time.current.beginning_of_month).count,
      messages_sent: 0,
      storage_used_mb: 0
    }
  end

  def within_limits?
    usage = usage_this_month
    limits = usage_limits
    
    usage[:chats_created] < limits[:chats_per_month] &&
    usage[:messages_sent] < limits[:messages_per_chat] &&
    usage[:storage_used_mb] < limits[:storage_mb]
  end
end
