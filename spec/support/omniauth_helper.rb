module OmniauthHelper
  def mock_omniauth_auth(provider, user_data = {})
    OmniAuth.config.test_mode = true
    
    OmniAuth.config.mock_auth[provider] = OmniAuth::AuthHash.new({
      provider: provider.to_s,
      uid: user_data[:did] || 'did:plc:test123',
      info: {
        did: user_data[:did] || 'did:plc:test123',
        handle: user_data[:handle] || 'test.user',
        display_name: user_data[:display_name] || 'Test User',
        avatar_url: user_data[:avatar_url] || 'https://example.com/avatar.jpg'
      },
      credentials: {
        token: 'mock_token',
        refresh_token: 'mock_refresh_token',
        expires_at: 1.hour.from_now.to_i
      }
    })
  end

  def mock_omniauth_failure(provider, error = 'access_denied')
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[provider] = :invalid_credentials
  end
end

RSpec.configure do |config|
  config.include OmniauthHelper
end
