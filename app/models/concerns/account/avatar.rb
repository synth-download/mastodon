# frozen_string_literal: true

module Account::Avatar
  extend ActiveSupport::Concern

  AVATAR_IMAGE_MIME_TYPES = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'].freeze
  AVATAR_ANIMATED_MIME_TYPES = ['image/gif', 'image/webp'].freeze
  AVATAR_LIMIT = Rails.configuration.x.use_vips ? 8.megabytes : 2.megabytes
  AVATAR_DIMENSIONS = [400, 400].freeze
  AVATAR_GEOMETRY = [AVATAR_DIMENSIONS.first, AVATAR_DIMENSIONS.last].join('x')

  class_methods do
    def avatar_styles(file)
      styles = { original: { geometry: "#{AVATAR_GEOMETRY}#", file_geometry_parser: FastGeometryParser } }
      styles[:static] = { geometry: "#{AVATAR_GEOMETRY}#", format: 'webp', convert_options: '-coalesce -delete 1--1', file_geometry_parser: FastGeometryParser } if AVATAR_ANIMATED_MIME_TYPES.include?(file.content_type)
      styles
    end

    private :avatar_styles
  end

  included do
    # Avatar upload
    has_attached_file :avatar, styles: ->(f) { avatar_styles(f) }, convert_options: { all: '+profile "!icc,*" +set date:modify +set date:create +set date:timestamp' }, processors: [:lazy_thumbnail]
    validates_attachment_content_type :avatar, content_type: AVATAR_IMAGE_MIME_TYPES
    validates_attachment_size :avatar, less_than: AVATAR_LIMIT
    remotable_attachment :avatar, AVATAR_LIMIT, suppress_errors: false
  end

  def avatar_original_url
    avatar.url(:original)
  end

  def avatar_static_url
    AVATAR_ANIMATED_MIME_TYPES.include?(avatar_content_type) ? avatar.url(:static) : avatar_original_url
  end
end
