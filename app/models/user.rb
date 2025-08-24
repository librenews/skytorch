class User < ApplicationRecord
  has_many :chats, dependent: :destroy
  has_many :messages, through: :chats
  has_many :llm_providers, dependent: :destroy

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
end
