# frozen_string_literal: true

class UnfavouriteService < BaseService
  include Payloadable

  def call(account, status)
    favourite = Favourite.find_by!(account: account, status: status)
    favourite.destroy!
    create_notification(favourite)
    favourite
  end

  private

  def create_notification(favourite)
    status = favourite.status

    return if status.local_only?

    if status.direct_visibility?
      ActivityPub::DeliveryWorker.perform_async(build_json(favourite), favourite.account_id, status.account.inbox_url) if status.account.activitypub?
    else
      ActivityPub::InteractionDistributionWorker.perform_async(build_json(favourite), favourite.account_id, status.id)
    end
  end

  def build_json(favourite)
    Oj.dump(serialize_payload(favourite, ActivityPub::UndoLikeSerializer))
  end
end
