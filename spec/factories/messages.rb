FactoryBot.define do
  factory :message do
    sequence(:content) { |n| "Message content #{n}" }
    role { "user" }
    association :chat

    trait :user do
      role { "user" }
      content { "Hello, how can you help me?" }
    end

    trait :assistant do
      role { "assistant" }
      content { "I'm here to help! What would you like to know?" }
    end

    trait :system do
      role { "system" }
      content { "You are a helpful AI assistant." }
    end

    trait :long_content do
      content { "This is a very long message with lots of content that might exceed normal limits and test how the system handles longer messages in the chat interface." * 5 }
    end

    trait :with_special_characters do
      content { "Message with special chars: @#$%^&*()_+-=[]{}|;':\",./<>?" }
    end
  end
end
