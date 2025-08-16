# frozen_string_literal: true

class Api::V1::Antennas::TagsController < Api::BaseController
  before_action -> { doorkeeper_authorize! :read, :'read:lists' }, only: [:show]
  before_action -> { doorkeeper_authorize! :write, :'write:lists' }, except: [:show]

  before_action :require_user!
  before_action :set_antenna

  def show
    @tags = load_tags
    @exclude_tags = load_exclude_tags
    render json: { tags: @tags, exclude_tags: @exclude_tags.pluck(:name) }
  end

  def create
    ApplicationRecord.transaction do
      tags.each do |tag|
        @antenna.antenna_tags.create!(tag: tag, exclude: false)
        @antenna.update!(any_tags: false) if @antenna.any_tags
      end
    end

    render_empty
  end

  def destroy
    AntennaTag.where(antenna: @antenna, tag: exist_tags).destroy_all
    @antenna.update!(any_tags: true) unless @antenna.antenna_tags.where(exclude: false).any?
    render_empty
  end

  private

  def set_antenna
    @antenna = Antenna.where(account: current_account).find(params[:antenna_id])
  end

  def load_tags
    @antenna.tags.pluck(:name)
  end

  def load_exclude_tags
    Tag.where(id: @antenna.exclude_tags || [])
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