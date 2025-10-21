# frozen_string_literal: true

class REST::ScheduledStatusSerializer < ActiveModel::Serializer
  attributes :id, :scheduled_at, :params

  has_many :media_attachments, serializer: REST::MediaAttachmentSerializer

  def id
    object.id.to_s
  end

  def params
    return object.params unless object.params&.dig('reblog', 'id')

    rendered = object.params.dup
    reblog_id = rendered['reblog']['id']

    status = Status.find_by(id: reblog_id)
    if status
      rendered['reblog'] = REST::StatusSerializer.new(status, scope: object.account.user, scope_name: :current_user)
    end

    rendered
  end
end
