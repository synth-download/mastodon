# frozen_string_literal: true

class Api::V1::Antennas::DomainsController < Api::BaseController
  before_action -> { doorkeeper_authorize! :read, :'read:lists' }, only: [:show]
  before_action -> { doorkeeper_authorize! :write, :'write:lists' }, except: [:show]

  before_action :require_user!
  before_action :set_antenna

  def show
    @domains = load_domains
    @exclude_domains = load_exclude_domains
    render json: { domains: @domains, exclude_domains: @exclude_domains }
  end

  def create
    ApplicationRecord.transaction do
      domains.each do |domain|
        @antenna.antenna_domains.create!(name: domain, exclude: false)
        @antenna.update!(any_domains: false) if @antenna.any_domains
      end
    end

    render_empty
  end

  def destroy
    AntennaDomain.where(antenna: @antenna, name: domains).destroy_all
    @antenna.update!(any_domains: true) unless @antenna.antenna_domains.where(exclude: false).any?
    render_empty
  end

  private

  def set_antenna
    @antenna = Antenna.where(account: current_account).find(params[:antenna_id])
  end

  def load_domains
    @antenna.antenna_domains.pluck(:name)
  end

  def load_exclude_domains
    @antenna.exclude_domains || []
  end

  def domains
    Array(resource_params[:domains])
  end

  def resource_params
    params.permit(domains: [])
  end
end