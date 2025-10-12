# frozen_string_literal: true

class ActivityPub::InteractionDistributionWorker < ActivityPub::RawDistributionWorker

  def perform(payload, account_id, status_id)
    @payload = payload
    return true if @payload.nil?

    @status = Status.find(status_id)
    @account = Account.find(account_id)

    distribute!
  rescue ActiveRecord::RecordNotFound
    true
  end

  protected

  def inboxes
    @inboxes ||= inbox_resolver.followers_inboxes
  end

  def payload
    @payload
  end

  def inbox_resolver
    @inbox_resolver ||= ActivityPub::InboxFinder.new(status: @status, account: @account)
  end
end
