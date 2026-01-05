# frozen_string_literal: true

class ActivityPub::InboxFinder
  def initialize(status:, account:)
    @status = status
    @account = account
  end

  def followers_inboxes
    scope = followers_scope
    inboxes = inboxes_without_suspended_for(scope)
    inboxes |= [@status.account.preferred_inbox_url]
    inboxes
  end

  private

  def followers_scope
    if @status.in_reply_to_local_account? && distributable?
      @account.followers.or(@status.thread.account.followers.not_domain_blocked_by_account(@account))
    elsif @status.direct_visibility? || @status.limited_visibility?
      Account.none
    else
      @account.followers
    end
  end

  def inboxes_without_suspended_for(scope)
    scope.merge!(Account.without_suspended)
    scope.inboxes
  end

  def distributable?
    @status.public_visibility? || @status.unlisted_visibility?
  end
end
