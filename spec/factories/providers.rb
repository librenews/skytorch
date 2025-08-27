FactoryBot.define do
  factory :provider do
    sequence(:name) { |n| "Provider #{n}" }
    provider_type { "openai" } # Use openai by default to avoid base_url requirement
    api_key { "test_api_key_#{SecureRandom.hex(8)}" }
    default_model { "gpt-4o-mini" }
    is_active { true }
    association :user

    trait :openai do
      name { "OpenAI" }
      provider_type { "openai" }
      default_model { "gpt-4o-mini" }
    end

    trait :anthropic do
      name { "Anthropic" }
      provider_type { "anthropic" }
      default_model { "claude-3-5-sonnet-20241022" }
    end

    trait :google do
      name { "Google" }
      provider_type { "google" }
      default_model { "gemini-1.5-flash" }
      base_url { "https://generativelanguage.googleapis.com" }
    end

    trait :mock do
      name { "Mock Provider" }
      provider_type { "mock" }
      api_key { "mock_key" }
      default_model { "mock-model" }
    end

    trait :inactive do
      is_active { false }
    end

    trait :global do
      user { nil }
      provider_type { "openai" } # Use openai to avoid base_url requirement
    end
  end
end
