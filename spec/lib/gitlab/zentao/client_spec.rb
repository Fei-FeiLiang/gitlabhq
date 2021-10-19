# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Zentao::Client do
  subject(:integration) { described_class.new(zentao_integration) }

  let(:zentao_integration) { create(:zentao_integration) }

  def mock_get_products_url
    integration.send(:url, "products/#{zentao_integration.zentao_product_xid}")
  end

  def mock_fetch_issue_url(issue_id)
    integration.send(:url, "issues/#{issue_id}")
  end

  let(:mock_headers) do
    {
      headers: {
        'Content-Type' => 'application/json',
        'Token' => zentao_integration.api_token
      }
    }
  end

  describe '#new' do
    context 'if integration is nil' do
      let(:zentao_integration) { nil }

      it 'raises ConfigError' do
        expect { integration }.to raise_error(described_class::ConfigError)
      end
    end

    context 'integration is provided' do
      it 'is initialized successfully' do
        expect { integration }.not_to raise_error
      end
    end
  end

  describe '#fetch_product' do
    context 'with valid product' do
      let(:mock_response) { { 'id' => zentao_integration.zentao_product_xid } }

      before do
        WebMock.stub_request(:get, mock_get_products_url)
               .with(mock_headers).to_return(status: 200, body: mock_response.to_json)
      end

      it 'fetches the product' do
        expect(integration.fetch_product(zentao_integration.zentao_product_xid)).to eq mock_response
      end
    end

    context 'with invalid product' do
      before do
        WebMock.stub_request(:get, mock_get_products_url)
               .with(mock_headers).to_return(status: 404, body: {}.to_json)
      end

      it 'fetches the empty product' do
        expect do
          integration.fetch_product(zentao_integration.zentao_product_xid)
        end.to raise_error(Gitlab::Zentao::Client::Error)
      end
    end

    context 'with invalid response' do
      before do
        WebMock.stub_request(:get, mock_get_products_url)
               .with(mock_headers).to_return(status: 200, body: '[invalid json}')
      end

      it 'fetches the empty product' do
        expect do
          integration.fetch_product(zentao_integration.zentao_product_xid)
        end.to raise_error(Gitlab::Zentao::Client::Error)
      end
    end
  end

  describe '#ping' do
    context 'with valid resource' do
      before do
        WebMock.stub_request(:get, mock_get_products_url)
               .with(mock_headers).to_return(status: 200, body: { 'deleted' => '0' }.to_json)
      end

      it 'responds with success' do
        expect(integration.ping[:success]).to eq true
      end
    end

    context 'with deleted resource' do
      before do
        WebMock.stub_request(:get, mock_get_products_url)
               .with(mock_headers).to_return(status: 200, body: { 'deleted' => '1' }.to_json)
      end

      it 'responds with unsuccess' do
        expect(integration.ping[:success]).to eq false
      end
    end
  end

  describe '#fetch_issue' do
    context 'with invalid id' do
      let(:invalid_ids) { ['story', 'story-', '-', '123', ''] }

      it 'returns empty object' do
        invalid_ids.each do |id|
          expect { integration.fetch_issue(id) }.to raise_error(Gitlab::Zentao::Client::Error)
        end
      end
    end

    context 'with valid id' do
      let(:valid_ids) { %w[story-1 bug-23] }

      it 'fetches current issue' do
        valid_ids.each do |id|
          WebMock.stub_request(:get, mock_fetch_issue_url(id))
                 .with(mock_headers).to_return(status: 200, body: { issue: { id: id } }.to_json)

          expect(integration.fetch_issue(id).dig('issue', 'id')).to eq id
        end
      end
    end
  end
end
