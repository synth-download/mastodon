# frozen_string_literal: true

class Api::V1::ListsController < Api::BaseController
  before_action -> { doorkeeper_authorize! :read, :'read:lists' }, only: [:index, :show]
  before_action -> { doorkeeper_authorize! :write, :'write:lists' }, except: [:index, :show]

  before_action :require_user!
  before_action :set_list, except: [:index, :create]

  def index
    @lists = List.where(account: current_account).all
    render json: @lists, each_serializer: REST::ListSerializer
  end

  def show
    render json: @list, serializer: REST::ListSerializer
  end

  def create
    raw = params.require(:list)
    
    attrs = raw.permit(:title, :replies_policy, :exclusive, :with_media_only, :ignore_reblog)
    @list = current_account.owned_lists.new(attrs)

    if raw.key?(:include_keywords)
      @list.include_keywords = normalize_groups(raw[:include_keywords])
    end

    if raw.key?(:exclude_keywords)
      @list.exclude_keywords = normalize_groups(raw[:exclude_keywords])
    end

    if @list.save
      render json: @list, serializer: REST::ListSerializer, status: :created
    else
      render json: { errors: @list.errors }, status: :unprocessable_entity
    end
  end

  def update
    raw = params.require(:list)
    
    attrs = raw.permit(:title, :replies_policy, :exclusive, :with_media_only, :ignore_reblog)
    @list.assign_attributes(attrs)

    if raw.key?(:include_keywords)
      @list.include_keywords = normalize_groups(raw[:include_keywords])
    end

    if raw.key?(:exclude_keywords)
      @list.exclude_keywords = normalize_groups(raw[:exclude_keywords])
    end

    if @list.save
      render json: @list, serializer: REST::ListSerializer
    else
      render json: { errors: @list.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @list.destroy!
    render_empty
  end

  private

  def normalize_groups(groups)
    return [] if groups.nil?
    groups = groups.is_a?(String) ? (JSON.parse(groups) rescue []) : groups

    unless groups.is_a?(Array)
      return []
    end

    groups.map do |group|
      g = group.is_a?(Array) ? group : Array(group)
      g.map(&:to_s).map(&:strip).reject(&:blank?)
    end.reject(&:empty?)
  end

  def set_list
    @list = List.where(account: current_account).find(params[:id])
  end

  def list_params
    params.permit(:title, :replies_policy, :exclusive, :with_media_only, :ignore_reblog, include_keywords: [], exclude_keywords: [])
  end
end