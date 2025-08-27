class ProvidersController < ApplicationController
  before_action :set_provider, only: [:update, :destroy, :set_default]

  def index
    @providers = ProviderService.available_providers
    @new_provider = Provider.new
  end

  def create
    provider_type = params[:provider][:provider_type]
    api_key = params[:provider][:api_key]

    case provider_type
    when 'openai'
      provider = ProviderService.create_openai_provider(api_key)
    when 'anthropic'
      provider = ProviderService.create_anthropic_provider(api_key)
    when 'google'
      provider = ProviderService.create_google_provider(api_key)
    when 'mock'
      provider = ProviderService.create_mock_provider
    else
      redirect_to providers_path, alert: "Invalid provider type"
      return
    end

    if provider.persisted?
      redirect_to providers_path, notice: "#{provider.name} provider was successfully created."
    else
      redirect_to providers_path, alert: "Failed to create provider: #{provider.errors.full_messages.join(', ')}"
    end
  rescue => e
    redirect_to providers_path, alert: "Failed to create provider: #{e.message}"
  end

  def update
    if @provider.update(provider_params)
      redirect_to providers_path, notice: "Provider was successfully updated."
    else
      redirect_to providers_path, alert: "Failed to update provider."
    end
  end

  def destroy
    @provider.destroy
    redirect_to providers_path, notice: "Provider was successfully deleted."
  end

  def set_default
    ProviderService.set_default_provider(@provider.id)
    redirect_to providers_path, notice: "#{@provider.name} is now the default provider."
  end

  private

  def set_provider
    @provider = Provider.find(params[:id])
  end

  def provider_params
    params.require(:provider).permit(:name, :provider_type, :api_key, :base_url, :default_model, :is_active)
  end
end
