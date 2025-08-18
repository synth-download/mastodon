# frozen_string_literal: true

class ActivityPub::FetchStatusWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'pull', retry: 3

  def perform(status_uri, options = {})
    ActivityPub::FetchRemoteStatusService.new.call(status_uri, **options.deep_symbolize_keys)
  rescue ActiveRecord::RecordNotFound
    true
  end
end
