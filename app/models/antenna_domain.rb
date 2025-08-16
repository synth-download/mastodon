# frozen_string_literal: true

# == Schema Information
#
# Table name: antenna_domains
#
#  id         :bigint(8)        not null, primary key
#  antenna_id :bigint(8)        not null
#  name       :string
#  exclude    :boolean          default(FALSE), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class AntennaDomain < ApplicationRecord
  belongs_to :antenna

  validate :limit_per_antenna

  validates :name, uniqueness: { scope: :antenna_id }

  private

  def limit_per_antenna
    raise Mastodon::ValidationError, I18n.t('antennas.errors.limit.domains') if AntennaDomain.where(antenna_id: antenna_id).count >= Antenna::DOMAINS_PER_ANTENNA_LIMIT
  end
end