class DashboardController < ApplicationController
  def index
    @chats = Chat.order(created_at: :desc).limit(10)
    @llm_providers = LlmProvider.active
    @current_provider = LlmProvider.default_provider
  end
end
