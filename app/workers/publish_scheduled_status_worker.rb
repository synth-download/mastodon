# frozen_string_literal: true

class PublishScheduledStatusWorker
  include Sidekiq::Worker

  sidekiq_options lock: :until_executed, lock_ttl: 1.hour.to_i

  def perform(scheduled_status_id)
    scheduled_status = ScheduledStatus.find(scheduled_status_id)
    scheduled_status.destroy!

    return true if scheduled_status.account.user_disabled?

    params = scheduled_status.params.with_indifferent_access

    if params[:reblog].present?
      reblog_id = params[:reblog]['id'] || params[:reblog][:id]
      reblog = Status.find_by(id: reblog_id)

      if reblog
        options = options_with_objects(params.except(:reblog))
        ReblogService.new.call(scheduled_status.account, reblog, options)
      end
    else
      PostStatusService.new.call(
        scheduled_status.account,
        options_with_objects(scheduled_status.params.with_indifferent_access)
      )
    end
  rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid
    true
  end

  def options_with_objects(options)
    options.tap do |options_hash|
      options_hash[:application] = Doorkeeper::Application.find(options_hash.delete(:application_id)) if options[:application_id]
      options_hash[:thread]      = Status.find(options_hash.delete(:in_reply_to_id)) if options_hash[:in_reply_to_id]
      options_hash[:quoted_status] = Status.find(options_hash.delete(:quoted_status_id)) if options_hash[:quoted_status_id]
    end
  end
end
