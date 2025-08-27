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

    trait :with_usage do
      role { "assistant" }
      prompt_tokens { 50 }
      completion_tokens { 25 }
      total_tokens { 75 }
      usage_data { { "model" => "gpt-4o-mini", "estimated" => false } }
    end

    trait :openai_usage do
      role { "assistant" }
      prompt_tokens { 100 }
      completion_tokens { 50 }
      total_tokens { 150 }
      usage_data { 
        { 
          "prompt_tokens" => 100,
          "completion_tokens" => 50,
          "total_tokens" => 150,
          "model" => "gpt-4o-mini"
        } 
      }
    end

    trait :anthropic_usage do
      role { "assistant" }
      prompt_tokens { 80 }
      completion_tokens { 40 }
      total_tokens { 120 }
      usage_data { 
        { 
          "input_tokens" => 80,
          "output_tokens" => 40,
          "model" => "claude-3-5-sonnet-20241022"
        } 
      }
    end

    trait :google_usage do
      role { "assistant" }
      prompt_tokens { 60 }
      completion_tokens { 30 }
      total_tokens { 90 }
      usage_data { 
        { 
          "promptTokenCount" => 60,
          "candidatesTokenCount" => 30,
          "totalTokenCount" => 90,
          "model" => "gemini-1.5-flash"
        } 
      }
    end

    trait :long_content do
      content { "This is a very long message with lots of content that might exceed normal limits and test how the system handles longer messages in the chat interface." * 5 }
    end

    trait :with_special_characters do
      content { "Message with special chars: @#$%^&*()_+-=[]{}|;':\",./<>?" }
    end
  end
end
