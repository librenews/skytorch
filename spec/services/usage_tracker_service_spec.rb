require 'rails_helper'

RSpec.describe UsageTrackerService, type: :service do
  let(:provider) { create(:provider, provider_type: 'openai') }

  describe '.extract_usage' do
    context 'with OpenAI response' do
      let(:llm_response) do
        {
          'content' => 'Test response',
          'usage' => {
            'prompt_tokens' => 100,
            'completion_tokens' => 50,
            'total_tokens' => 150
          }
        }
      end

      it 'extracts usage data correctly' do
        usage_data = UsageTrackerService.extract_usage('openai', llm_response)
        
        expect(usage_data.prompt_tokens).to eq(100)
        expect(usage_data.completion_tokens).to eq(50)
        expect(usage_data.total_tokens).to eq(150)
        expect(usage_data.raw_data).to eq(llm_response['usage'])
      end

      it 'handles missing usage data' do
        llm_response_without_usage = { 'content' => 'Test response' }
        usage_data = UsageTrackerService.extract_usage('openai', llm_response_without_usage)
        
        expect(usage_data.prompt_tokens).to be_nil
        expect(usage_data.completion_tokens).to be_nil
        expect(usage_data.total_tokens).to be_nil
        expect(usage_data.raw_data).to eq({})
      end
    end

    context 'with Anthropic response' do
      let(:llm_response) do
        {
          'content' => 'Test response',
          'usage' => {
            'input_tokens' => 100,
            'output_tokens' => 50
          }
        }
      end

      it 'maps Anthropic token names correctly' do
        usage_data = UsageTrackerService.extract_usage('anthropic', llm_response)
        
        expect(usage_data.prompt_tokens).to eq(100)
        expect(usage_data.completion_tokens).to eq(50)
        expect(usage_data.total_tokens).to eq(150)
      end
    end

    context 'with Google response' do
      let(:llm_response) do
        {
          'content' => 'Test response',
          'usageMetadata' => {
            'promptTokenCount' => 100,
            'candidatesTokenCount' => 50,
            'totalTokenCount' => 150
          }
        }
      end

      it 'maps Google token names correctly' do
        usage_data = UsageTrackerService.extract_usage('google', llm_response)
        
        expect(usage_data.prompt_tokens).to eq(100)
        expect(usage_data.completion_tokens).to eq(50)
        expect(usage_data.total_tokens).to eq(150)
      end
    end
  end

  describe '.calculate_cost' do
    let(:usage_data) do
      double(
        prompt_tokens: 100,
        completion_tokens: 50,
        total_tokens: 150,
        raw_data: {}
      )
    end

    context 'with OpenAI pricing' do
      it 'calculates cost for GPT-4o-mini' do
        cost = UsageTrackerService.calculate_cost(usage_data, 'openai', 'gpt-4o-mini')
        
        # Expected: (100 * 0.005 + 50 * 0.015) / 1000
        expected_cost = (100 * 0.005 + 50 * 0.015) / 1000.0
        expect(cost).to eq(expected_cost)
      end

      it 'calculates cost for GPT-4o' do
        cost = UsageTrackerService.calculate_cost(usage_data, 'openai', 'gpt-4o')
        
        # Expected: (100 * 0.005 + 50 * 0.015) / 1000
        expected_cost = (100 * 0.005 + 50 * 0.015) / 1000.0
        expect(cost).to eq(expected_cost)
      end

      it 'uses default pricing for unknown models' do
        cost = UsageTrackerService.calculate_cost(usage_data, 'openai', 'unknown-model')
        
        # Should use GPT-4o pricing as default
        expected_cost = (100 * 0.005 + 50 * 0.015) / 1000.0
        expect(cost).to eq(expected_cost)
      end
    end

    context 'with Anthropic pricing' do
      it 'calculates cost for Claude 3.5 Sonnet' do
        cost = UsageTrackerService.calculate_cost(usage_data, 'anthropic', 'claude-3-5-sonnet-20241022')
        
        # Expected: (100 * 0.003 + 50 * 0.015) / 1000
        expected_cost = (100 * 0.003 + 50 * 0.015) / 1000.0
        expect(cost).to be_within(0.000001).of(expected_cost)
      end

      it 'calculates cost for Claude 3 Haiku' do
        cost = UsageTrackerService.calculate_cost(usage_data, 'anthropic', 'claude-3-haiku-20240307')
        
        # Expected: (100 * 0.003 + 50 * 0.015) / 1000 (default pricing)
        expected_cost = (100 * 0.003 + 50 * 0.015) / 1000.0
        expect(cost).to be_within(0.000001).of(expected_cost)
      end

      it 'uses default pricing for unknown models' do
        cost = UsageTrackerService.calculate_cost(usage_data, 'anthropic', 'unknown-model')
        
        # Should use Claude 3.5 Sonnet pricing as default
        expected_cost = (100 * 0.003 + 50 * 0.015) / 1000.0
        expect(cost).to be_within(0.000001).of(expected_cost)
      end
    end

    context 'with Google pricing' do
      it 'calculates cost for Gemini 1.5 Flash' do
        cost = UsageTrackerService.calculate_cost(usage_data, 'google', 'gemini-1.5-flash')
        
        # Expected: (100 * 0.000075 + 50 * 0.0003) / 1000
        expected_cost = (100 * 0.000075 + 50 * 0.0003) / 1000.0
        expect(cost).to eq(expected_cost)
      end

      it 'calculates cost for Gemini 1.5 Pro' do
        cost = UsageTrackerService.calculate_cost(usage_data, 'google', 'gemini-1.5-pro')
        
        # Expected: (100 * 0.00375 + 50 * 0.015) / 1000
        expected_cost = (100 * 0.00375 + 50 * 0.015) / 1000.0
        expect(cost).to be_within(0.000001).of(expected_cost)
      end

      it 'uses default pricing for unknown models' do
        cost = UsageTrackerService.calculate_cost(usage_data, 'google', 'unknown-model')
        
        # Should use Gemini 1.5 Flash pricing as default
        expected_cost = (100 * 0.000075 + 50 * 0.0003) / 1000.0
        expect(cost).to eq(expected_cost)
      end
    end

    context 'with unknown provider' do
      it 'uses generic fallback pricing for unknown providers' do
        cost = UsageTrackerService.calculate_cost(usage_data, 'unknown', 'unknown-model')
        
        # Expected: (100 * 0.001 + 50 * 0.003) / 1000
        expected_cost = (100 * 0.001 + 50 * 0.003) / 1000.0
        expect(cost).to eq(expected_cost)
      end
    end
  end


end
