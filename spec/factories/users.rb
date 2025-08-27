FactoryBot.define do
  factory :user do
    sequence(:bluesky_handle) { |n| "user#{n}.bsky.social" }
    sequence(:bluesky_did) { |n| "did:plc:user#{n}" }
    sequence(:display_name) { |n| "User #{n}" }
    avatar_url { "https://api.dicebear.com/7.x/avataaars/svg?seed=#{bluesky_handle}" }
    is_admin { false }
    description { "User description" }
    profile_updated_at { Time.current }

    trait :with_providers do
      after(:create) do |user|
        create_list(:provider, 2, user: user)
      end
    end

    trait :with_chats do
      after(:create) do |user|
        create_list(:chat, 3, user: user)
      end
    end

    trait :admin do
      is_admin { true }
    end
  end
end
