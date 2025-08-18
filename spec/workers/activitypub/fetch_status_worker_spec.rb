# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ActivityPub::FetchStatusWorker do
  subject { described_class.new }

  let(:status_uri) { 'https://example.com/statuses/123' }

  describe 'perform' do
    it 'performs a request to the remote server' do
      stub_request(:get, 'https://example.com/statuses/123').to_return(status: 200, body: json, headers: { 'Content-Type': 'application/activity+json' })
      subject.perform(status.id, 'https://example.com/statuses_replies/1')
      expect(a_request(:get, 'https://example.com/statuses_replies/1')).to have_been_made.once
    end

    it 'raises when request fails' do
      stub_request(:get, 'https://example.com/statuses/123').to_return(status: 500)
      expect { subject.perform(status.id, 'https://example.com/statuses/123') }.to raise_error Mastodon::UnexpectedResponseError
    end
  end
end
