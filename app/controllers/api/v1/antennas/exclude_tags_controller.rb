# frozen_string_literal: true

class Api::V1::Antennas::ExcludeTagsController < Api::BaseController
  before_action -> { doorkeeper_authorize! :write, :'write:lists' }

  before_action :require_user!
  before_action :set_antenna

  def create
    new_tags = @antenna.exclude_tags || []
    tags.map(&:id).each do |tag|
      raise Mastodon::ValidationError, I18n.t('antennas.errors.duplicate_tag') if new_tags.include?(tag)

      new_tags << tag
    end

    raise Mastodon::ValidationError, I18n.t('antennas.errors.limit.tags') if new_tags.size > Antenna::TAGS_PER_ANTENNA_LIMIT

    @antenna.update!(exclude_tags: new_tags)

    render_empty
  end

  def destroy
    new_tags = @antenna.exclude_tags || []
    new_tags -= exist_tags.pluck(:id)

    @antenna.update!(exclude_tags: new_tags)

    render_empty
  end

  private

  def set_antenna
    @antenna = Antenna.where(account: current_account).find(params[:antenna_id])
  end

  def tags
    Tag.find_or_create_by_names(Array(resource_params[:tags]))
  end

  def exist_tags
    Tag.matching_name(Array(resource_params[:tags]))
  end

  def resource_params
    params.permit(tags: [])
  end
end