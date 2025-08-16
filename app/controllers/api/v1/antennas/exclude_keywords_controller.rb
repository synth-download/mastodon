# frozen_string_literal: true

class Api::V1::Antennas::ExcludeKeywordsController < Api::BaseController
  before_action -> { doorkeeper_authorize! :write, :'write:lists' }

  before_action :require_user!
  before_action :set_antenna

  def create
    new_keywords = @antenna.exclude_keywords || []
    keywords.each do |keyword|
      raise Mastodon::ValidationError, I18n.t('antennas.errors.duplicate_keyword') if new_keywords.include?(keyword)

      new_keywords << keyword
    end

    raise Mastodon::ValidationError, I18n.t('antennas.errors.limit.keywords') if new_keywords.size > Antenna::KEYWORDS_PER_ANTENNA_LIMIT

    @antenna.update!(exclude_keywords: new_keywords)

    render_empty
  end

  def destroy
    new_keywords = @antenna.exclude_keywords || []
    new_keywords -= keywords

    @antenna.update!(exclude_keywords: new_keywords)

    render_empty
  end

  private

  def set_antenna
    @antenna = Antenna.where(account: current_account).find(params[:antenna_id])
  end

  def keywords
    Array(resource_params[:keywords])
  end

  def resource_params
    params.permit(keywords: [])
  end
end