require_relative '../../lib/omniauth/atproto/key_manager'

Rails.application.config.middleware.use OmniAuth::Builder do
  app_url = Rails.application.config.respond_to?(:app_url) ? Rails.application.config.app_url : "https://dev.libre.news"
  
  # Use the omniauth-atproto strategy
  provider(:atproto,
    "#{app_url}/oauth/client-metadata.json",
    nil,
    client_options: {
        site: "https://bsky.social",
        authorize_url: "https://bsky.social/oauth/authorize",
        token_url: "https://bsky.social/oauth/token"
    },
    scope: "atproto transition:generic transition:chat.bsky",
    private_key: OmniAuth::Atproto::KeyManager.current_private_key,
    client_jwk: OmniAuth::Atproto::KeyManager.current_jwk)
end

# Configure OmniAuth settings
OmniAuth.config.allowed_request_methods = [:post, :get]
OmniAuth.config.silence_get_warning = true
