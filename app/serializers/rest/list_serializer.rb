# frozen_string_literal: true

class REST::ListSerializer < ActiveModel::Serializer
  attributes :id,
             :title,
             :replies_policy,
             :exclusive,
             :include_keywords,
             :exclude_keywords,
             :with_media_only,
             :ignore_reblog

  def id
    object.id.to_s
  end
end
