# frozen_string_literal: true

class AddBubbleTimelinePreviewSetting < ActiveRecord::Migration[8.0]
  class Setting < ApplicationRecord; end

  def up
    setting = Setting.find_by(var: 'remote_live_feed_access')
    return unless setting.present? && setting.attributes['value'].present?

    value = YAML.safe_load(setting.attributes['value'], permitted_classes: [ActiveSupport::HashWithIndifferentAccess, Symbol])

    Setting.upsert(
      { var: 'bubble_live_feed_access', value: value },
      unique_by: :var
    )
  end

  def down; end
end
