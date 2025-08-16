# frozen_string_literal: true

class Api::V1::Antennas::AccountsController < Api::BaseController
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
    ApplicationRecord.transaction do
      antenna_accounts.each do |account|
        @antenna.antenna_accounts.create!(account: account, exclude: false)
        @antenna.update!(any_accounts: false) if @antenna.any_accounts
      end
    end

    render_empty
  end

  def destroy
    AntennaAccount.where(antenna: @antenna, account_id: account_ids).destroy_all
    @antenna.update!(any_accounts: true) unless @antenna.antenna_accounts.where(exclude: false).any?
    render_empty
  end

  private

  def set_antenna
    @antenna = Antenna.where(account: current_account).find(params[:antenna_id])
  end

  def load_accounts
    if unlimited?
      @antenna.accounts.without_suspended.includes(:account_stat).all
    else
      @antenna.accounts.without_suspended.includes(:account_stat).paginate_by_max_id(limit_param(DEFAULT_ACCOUNTS_LIMIT), params[:max_id], params[:since_id])
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