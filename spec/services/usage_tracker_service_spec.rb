require 'rails_helper'

RSpec.describe UsageTrackerService, type: :service do
  describe '.extract_usage' do
    context 'with OpenAI response' do
      let(:openai_response) do
        {
          'content' => 'Hello, how can I help you?',
          'usage' => {
            'prompt_tokens' => 100,
            'completion_tokens' => 50,
            'total_tokens' => 150
          }
        }
      end

      it 'extracts usage data correctly' do
        usage_data = UsageTrackerService.extract_usage('openai', openai_response)
        
        expect(usage_data.prompt_tokens).to eq(100)
        expect(usage_data.completion_tokens).to eq(50)
        expect(usage_data.total_tokens).to eq(150)
        expect(usage_data.raw_data).to eq(openai_response['usage'])
      end
    end

    context 'with Anthropic response' do
      let(:anthropic_response) do
        {
          'content' => 'Hello, how can I help you?',
          'usage' => {
            'input_tokens' => 80,
            'output_tokens' => 40
          }
        }
      end

      it 'extracts usage data correctly' do
        usage_data = UsageTrackerService.extract_usage('anthropic', anthropic_response)
        
        expect(usage_data.prompt_tokens).to eq(80)
        expect(usage_data.completion_tokens).to eq(40)
        expect(usage_data.total_tokens).to eq(120)
        expect(usage_data.raw_data).to eq(anthropic_response['usage'])
      end
    end

    context 'with Google response' do
      let(:google_response) do
        {
          'content' => 'Hello, how can I help you?',
          'usageMetadata' => {
            'promptTokenCount' => 60,
            'candidatesTokenCount' => 30,
            'totalTokenCount' => 90
          }
        }
      end

      it 'extracts usage data correctly' do
        usage_data = UsageTrackerService.extract_usage('google', google_response)
        
        expect(usage_data.prompt_tokens).to eq(60)
        expect(usage_data.completion_tokens).to eq(30)
        expect(usage_data.total_tokens).to eq(90)
        expect(usage_data.raw_data).to eq(google_response['usageMetadata'])
      end
    end

    context 'with mock response' do
      let(:mock_response) do
        {
          'content' => 'Hello, how can I help you? This is a test response with some content.'
        }
      end

      it 'estimates usage data correctly' do
        usage_data = UsageTrackerService.extract_usage('mock', mock_response)
        
        expect(usage_data.prompt_tokens).to eq(10)
        expect(usage_data.completion_tokens).to be > 0
        expect(usage_data.total_tokens).to be > 10
        expect(usage_data.raw_data[:estimated]).to be true
      end
    end

    context 'with unknown provider' do
      let(:unknown_response) do
        {
          'content' => 'Hello',
          'some_usage_data' => { 'tokens' => 100 }
        }
      end

      it 'returns nil values for unknown providers' do
        usage_data = UsageTrackerService.extract_usage('unknown', unknown_response)
        
        expect(usage_data.prompt_tokens).to be_nil
        expect(usage_data.completion_tokens).to be_nil
        expect(usage_data.total_tokens).to be_nil
        expect(usage_data.raw_data).to eq(unknown_response)
      end
    end

    context 'with missing usage data' do
      let(:response_without_usage) do
        {
          'content' => 'Hello, how can I help you?'
        }
      end

      it 'handles missing usage data gracefully' do
        usage_data = UsageTrackerService.extract_usage('openai', response_without_usage)
        
        expect(usage_data.prompt_tokens).to be_nil
        expect(usage_data.completion_tokens).to be_nil
        expect(usage_data.total_tokens).to be_nil
        expect(usage_data.raw_data).to eq({})
      end
    end
  end

  describe '.calculate_cost' do
    let(:usage_data) do
      UsageTrackerService::UsageData.new(
        prompt_tokens: 100,
        completion_tokens: 50,
        total_tokens: 150,
        raw_data: {}
      )
    end

    context 'with OpenAI pricing' do
      it 'calculates cost for GPT-4o-mini' do
        cost = UsageTrackerService.calculate_cost(usage_data, 'openai', 'gpt-4o-mini')
        
        # 100 * 0.005 / 1000 + 50 * 0.015 / 1000 = 0.0005 + 0.00075 = 0.00125
        expected_cost = (100 * 0.005 / 1000.0) + (50 * 0.015 / 1000.0)
        expect(cost).to eq(expected_cost)
      end

      it 'calculates cost for GPT-3.5-turbo' do
        cost = UsageTrackerService.calculate_cost(usage_data, 'openai', 'gpt-3.5-turbo')
        
        # 100 * 0.0005 / 1000 + 50 * 0.0015 / 1000 = 0.00005 + 0.000075 = 0.000125
        expected_cost = (100 * 0.0005 / 1000.0) + (50 * 0.0015 / 1000.0)
        expect(cost).to eq(expected_cost)
      end
    end

    context 'with Anthropic pricing' do
      it 'calculates cost for Claude-3-5-Sonnet' do
        cost = UsageTrackerService.calculate_cost(usage_data, 'anthropic', 'claude-3-5-sonnet-20241022')
        
        # 100 * 0.003 / 1000 + 50 * 0.015 / 1000 = 0.0003 + 0.00075 = 0.00105
        expected_cost = (100 * 0.003 / 1000.0) + (50 * 0.015 / 1000.0)
        expect(cost).to eq(expected_cost)
      end
    end

    context 'with Google pricing' do
      it 'calculates cost for Gemini-1.5-Flash' do
        cost = UsageTrackerService.calculate_cost(usage_data, 'google', 'gemini-1.5-flash')
        
        # 100 * 0.000075 / 1000 + 50 * 0.0003 / 1000 = 0.0000075 + 0.000015 = 0.0000225
        expected_cost = (100 * 0.000075 / 1000.0) + (50 * 0.0003 / 1000.0)
        expect(cost).to eq(expected_cost)
      end
    end

    context 'with mock provider' do
      it 'returns zero cost for mock provider' do
        cost = UsageTrackerService.calculate_cost(usage_data, 'mock')
        expect(cost).to eq(0)
      end
    end

    context 'with nil usage data' do
      it 'returns zero cost when usage data is nil' do
        cost = UsageTrackerService.calculate_cost(nil, 'openai')
        expect(cost).to eq(0)
      end
    end

    context 'with unknown provider' do
      it 'uses generic fallback pricing' do
        cost = UsageTrackerService.calculate_cost(usage_data, 'unknown')
        
        # 100 * 0.001 / 1000 + 50 * 0.003 / 1000 = 0.0001 + 0.00015 = 0.00025
        expected_cost = (100 * 0.001 / 1000.0) + (50 * 0.003 / 1000.0)
        expect(cost).to eq(expected_cost)
      end
    end
  end

  describe 'UsageData struct' do
    it 'creates usage data with keyword arguments' do
      usage_data = UsageTrackerService::UsageData.new(
        prompt_tokens: 100,
        completion_tokens: 50,
        total_tokens: 150,
        raw_data: { 'model' => 'gpt-4o-mini' }
      )
      
      expect(usage_data.prompt_tokens).to eq(100)
      expect(usage_data.completion_tokens).to eq(50)
      expect(usage_data.total_tokens).to eq(150)
      expect(usage_data.raw_data).to eq({ 'model' => 'gpt-4o-mini' })
    end
  end
end
