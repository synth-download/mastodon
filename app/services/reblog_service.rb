# frozen_string_literal: true

class ReblogService < BaseService
  include Authorization
  include Payloadable

  # Reblog a status and notify its remote author
  # @param [Account] account Account to reblog from
  # @param [Status] reblogged_status Status to be reblogged
  # @param [Hash] options
  # @option [String]  :visibility
  # @option [String]  :scheduled_at
  # @option [Boolean] :with_rate_limit
  # @return [Status]
  def call(account, reblogged_status, options = {})
    @account = account
    @options = options
    @reblogged_status = reblogged_status.reblog? ? reblogged_status.reblog : reblogged_status

    authorize_with account, @reblogged_status, :reblog?

    @reblog = account.statuses.find_by(reblog: @reblogged_status)

    return @reblog unless @reblog.nil?

    @visibility = if @reblogged_status.hidden?
                   @reblogged_status.visibility
                 else
                   options[:visibility] || account.user&.setting_default_privacy
                 end

    if scheduled?
      schedule_reblog!
      return @reblog
    end

    @reblog = account.statuses.create!(reblog: @reblogged_status, text: '', visibility: @visibility, rate_limit: options[:with_rate_limit])

    Trends.register!(@reblog)
    DistributionWorker.perform_async(@reblog.id)
    ActivityPub::DistributionWorker.perform_async(@reblog.id) unless @reblogged_status.local_only?

    create_notification(@reblog)
    increment_statistics

    @reblog
  end

  private

  def schedule_reblog!
    ApplicationRecord.transaction do
      @reblog = @account.scheduled_statuses.create!(scheduled_status_attributes)
    end
  end

  def create_notification()
    reblogged_status = @reblog.reblog

    LocalNotificationWorker.perform_async(reblogged_status.account_id, @reblog.id, @reblog.class.name, 'reblog') if reblogged_status.account.local?
  end

  def increment_statistics
    ActivityTracker.increment('activity:interactions')
  end

  def scheduled?
    @options[:scheduled_at].present?
  end

  def scheduled_status_attributes
    {
      scheduled_at: @options[:scheduled_at],
      media_attachments: [],
      params: scheduled_options,
    }
  end

  def scheduled_options
    @options.dup.tap do |options_hash|
      options_hash[:scheduled_at] = nil
      options_hash[:media_ids] = []
      options_hash[:text]    = "🔁 #{ActivityPub::TagManager.instance.url_for(@reblogged_status)}"
      options_hash[:reblog]    = reblogged_status_json()
      options_hash[:visibility]    = @visibility
    end
  end

  def reblogged_status_json
    REST::StatusSerializer.new(@reblogged_status, scope: @account.user, scope_name: :current_user)
  end

  def build_json()
    Oj.dump(serialize_payload(ActivityPub::ActivityPresenter.from_status(@reblog), ActivityPub::ActivitySerializer, signer: @reblog.account))
  end
end
