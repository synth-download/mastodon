# frozen_string_literal: true

class Api::V1::Antennas::KeywordsController < Api::BaseController
  before_action -> { doorkeeper_authorize! :read, :'read:lists' }, only: [:show]
  before_action -> { doorkeeper_authorize! :write, :'write:lists' }, except: [:show]

  before_action :require_user!
  before_action :set_antenna

  def show
    @keywords = load_keywords
    @exclude_keywords = load_exclude_keywords
    render json: { keywords: @keywords, exclude_keywords: @exclude_keywords }
  end

  def create
    new_keywords = @antenna.keywords || []
    keywords.each do |keyword|
      raise Mastodon::ValidationError, I18n.t('antennas.errors.duplicate_keyword') if new_keywords.include?(keyword)
      raise Mastodon::ValidationError, I18n.t('antennas.errors.too_short_keyword') if keyword.length < 2

      new_keywords << keyword
    end

    raise Mastodon::ValidationError, I18n.t('antennas.errors.limit.keywords') if new_keywords.size > Antenna::KEYWORDS_PER_ANTENNA_LIMIT

    @antenna.update!(keywords: new_keywords, any_keywords: new_keywords.empty?)

    render_empty
  end

  def destroy
    new_keywords = @antenna.keywords || []
    new_keywords -= keywords

    @antenna.update!(keywords: new_keywords, any_keywords: new_keywords.empty?)

    render_empty
  end

  private

  def set_antenna
    @antenna = Antenna.where(account: current_account).find(params[:antenna_id])
  end

  def load_keywords
    @antenna.keywords || []
  end

  def load_exclude_keywords
    @antenna.exclude_keywords || []
  end

  def keywords
    Array(resource_params[:keywords])
  end

  def resource_params
    params.permit(keywords: [])
  end
end