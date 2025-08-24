class LlmProvidersController < ApplicationController
  before_action :set_llm_provider, only: [:update, :destroy, :set_default]
  
  def index
    @llm_providers = LlmProviderService.available_providers
    @new_provider = LlmProvider.new
  end

  def create
    provider_type = params[:llm_provider][:provider_type]
    api_key = params[:llm_provider][:api_key]
    
    case provider_type
    when "openai"
      provider = LlmProviderService.create_openai_provider(api_key)
    when "anthropic"
      provider = LlmProviderService.create_anthropic_provider(api_key)
    when "google"
      provider = LlmProviderService.create_google_provider(api_key)
    when "mock"
      provider = LlmProviderService.create_mock_provider
    else
      redirect_to llm_providers_path, alert: "Invalid provider type"
      return
    end
    
    redirect_to llm_providers_path, notice: "#{provider.name} provider was successfully created."
  rescue => e
    redirect_to llm_providers_path, alert: "Failed to create provider: #{e.message}"
  end

  def update
    if @llm_provider.update(llm_provider_params)
      redirect_to llm_providers_path, notice: "Provider was successfully updated."
    else
      redirect_to llm_providers_path, alert: "Failed to update provider."
    end
  end

  def destroy
    @llm_provider.destroy
    redirect_to llm_providers_path, notice: "Provider was successfully deleted."
  end
  
  def set_default
    LlmProviderService.set_default_provider(@llm_provider.id)
    redirect_to llm_providers_path, notice: "#{@llm_provider.name} is now the default provider."
  end
  
  private
  
  def set_llm_provider
    @llm_provider = LlmProvider.find(params[:id])
  end
  
  def llm_provider_params
    params.require(:llm_provider).permit(:name, :provider_type, :api_key, :base_url, :default_model, :is_active)
  end
end
