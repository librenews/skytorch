class User < ApplicationRecord
  has_many :chats, dependent: :destroy
  has_many :messages, through: :chats
  has_many :llm_providers, dependent: :destroy
  has_many :tools, dependent: :destroy

  validates :bluesky_did, presence: true, uniqueness: true
  validates :bluesky_handle, presence: true, uniqueness: true
  validates :display_name, presence: true

  scope :admins, -> { where(is_admin: true) }
  scope :active, -> { where.not(bluesky_did: nil) }

  def has_provider?
    llm_providers.exists?
  end

  def default_provider
    llm_providers.first || LlmProvider.global_default
  end

  def using_global_provider?
    !has_provider?
  end

  def avatar_display_url
    avatar_url.presence || "https://ui-avatars.com/api/?name=#{display_name}&background=6366f1&color=fff"
  end

  # Toolbox methods
  def toolbox
    tools.where(visibility: ['private', 'unlisted'])
  end
  
  def public_tools
    tools.where(visibility: 'public')
  end
  
  def add_to_toolbox(tool)
    tool.update(user: self, visibility: 'private') if tool.visibility == 'public'
  end
  
  def remove_from_toolbox(tool)
    tool.destroy if tool.user == self && tool.visibility == 'private'
  end

  # Profile caching methods
  def update_profile_cache!(profile_data)
    return unless profile_data
    
    self.bluesky_handle = profile_data[:handle] if profile_data[:handle]
    self.display_name = profile_data[:display_name] if profile_data[:display_name]
    self.avatar_url = profile_data[:avatar_url] if profile_data[:avatar_url]
    self.profile_cache = profile_data
    self.profile_updated_at = Time.current
    save!
  end

  def cached_profile_data
    profile_cache || {}
  end

  def profile_cache_stale?
    profile_updated_at.nil? || profile_updated_at < 1.hour.ago
  end

  def description
    cached_profile_data['description'] || cached_profile_data[:description]
  end

  def followers_count
    cached_profile_data['followers_count'] || cached_profile_data[:followers_count] || 0
  end

  def following_count
    cached_profile_data['following_count'] || cached_profile_data[:following_count] || 0
  end

  def posts_count
    cached_profile_data['posts_count'] || cached_profile_data[:posts_count] || 0
  end

  def refresh_profile_cache!
    at_service = AtProtocolService.new
    profile_data = at_service.get_profile(bluesky_handle || bluesky_did)
    if profile_data
      update_profile_cache!(profile_data)
      true
    else
      false
    end
  rescue => e
    Rails.logger.warn "Failed to refresh profile cache for user #{id}: #{e.message}"
    false
  end
end
