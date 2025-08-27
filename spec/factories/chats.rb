FactoryBot.define do
  factory :chat do
    sequence(:title) { |n| "Chat #{n}" }
    status { "active" }
    association :user

    trait :archived do
      status { "archived" }
    end

    trait :reported do
      status { "reported" }
    end

    trait :with_messages do
      after(:create) do |chat|
        create_list(:message, 3, chat: chat)
      end
    end

    trait :with_user_message do
      after(:create) do |chat|
        create(:message, :user, chat: chat)
      end
    end

    trait :with_assistant_message do
      after(:create) do |chat|
        create(:message, :assistant, chat: chat)
      end
    end

    trait :with_system_message do
      after(:create) do |chat|
        create(:message, :system, chat: chat)
      end
    end
  end
end
