# frozen_string_literal: true

class Api::V1::Antennas::ExcludeAccountsController < Api::BaseController
  before_action -> { doorkeeper_authorize! :read, :'read:lists' }, only: [:show]
  before_action -> { doorkeeper_authorize! :write, :'write:lists' }, except: [:show]

  before_action :require_user!
  before_action :set_antenna

  after_action :insert_pagination_headers, only: :show

  def show
    @accounts = load_accounts
    render json: @accounts, each_serializer: REST::AccountSerializer
  end

  def create
    new_accounts = @antenna.exclude_accounts || []
    antenna_accounts.each do |account|
      raise Mastodon::ValidationError, I18n.t('antennas.errors.duplicate_account') if new_accounts.include?(account.id)

      new_accounts << account.id
    end

    raise Mastodon::ValidationError, I18n.t('antennas.errors.limit.accounts') if new_accounts.size > Antenna::ACCOUNTS_PER_ANTENNA_LIMIT

    @antenna.update!(exclude_accounts: new_accounts)

    render_empty
  end

  def destroy
    new_accounts = @antenna.exclude_accounts || []
    new_accounts -= antenna_accounts.pluck(:id)

    @antenna.update!(exclude_accounts: new_accounts)

    render_empty
  end

  private

  def set_antenna
    @antenna = Antenna.where(account: current_account).find(params[:antenna_id])
  end

  def load_accounts
    return [] if @antenna.exclude_accounts.nil?

    if unlimited?
      Account.where(id: @antenna.exclude_accounts).without_suspended.includes(:account_stat).all
    else
      Account.where(id: @antenna.exclude_accounts).without_suspended.includes(:account_stat).paginate_by_max_id(limit_param(DEFAULT_ACCOUNTS_LIMIT), params[:max_id], params[:since_id])
    end
  end

  def antenna_accounts
    Account.find(account_ids)
  end

  def account_ids
    Array(resource_params[:account_ids])
  end

  def resource_params
    params.permit(account_ids: [])
  end

  def insert_pagination_headers
    set_pagination_headers(next_path, prev_path)
  end

  def next_path
    return if unlimited?

    api_v1_list_accounts_url pagination_params(max_id: pagination_max_id) if records_continue?
  end

  def prev_path
    return if unlimited?

    api_v1_list_accounts_url pagination_params(since_id: pagination_since_id) unless @accounts.empty?
  end

  def pagination_max_id
    @accounts.last.id
  end

  def pagination_since_id
    @accounts.first.id
  end

  def records_continue?
    @accounts.size == limit_param(DEFAULT_ACCOUNTS_LIMIT)
  end

  def pagination_params(core_params)
    params.slice(:limit).permit(:limit).merge(core_params)
  end

  def unlimited?
    params[:limit] == '0'
  end
end