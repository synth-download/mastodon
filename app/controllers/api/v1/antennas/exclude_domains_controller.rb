# frozen_string_literal: true

class Api::V1::Antennas::ExcludeDomainsController < Api::BaseController
  before_action -> { doorkeeper_authorize! :write, :'write:lists' }

  before_action :require_user!
  before_action :set_antenna

  def create
    new_domains = @antenna.exclude_domains || []
    domains.each do |domain|
      raise Mastodon::ValidationError, I18n.t('antennas.errors.duplicate_domain') if new_domains.include?(domain)

      new_domains << domain
    end

    raise Mastodon::ValidationError, I18n.t('antennas.errors.limit.domains') if new_domains.size > Antenna::KEYWORDS_PER_ANTENNA_LIMIT

    @antenna.update!(exclude_domains: new_domains)

    render_empty
  end

  def destroy
    new_domains = @antenna.exclude_domains || []
    new_domains -= domains

    @antenna.update!(exclude_domains: new_domains)

    render_empty
  end

  private

  def set_antenna
    @antenna = Antenna.where(account: current_account).find(params[:antenna_id])
  end

  def domains
    Array(resource_params[:domains])
  end

  def resource_params
    params.permit(domains: [])
  end
end