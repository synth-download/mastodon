# frozen_string_literal: true

# == Schema Information
#
# Table name: lists
#
#  id                 :bigint(8)        not null, primary key
#  account_id         :bigint(8)        not null
#  title              :string           default(""), not null
#  include_keywords   :jsonb            default([]), not null
#  exclude_keywords   :jsonb            default([]), not null
#  with_media_only    :boolean          default(FALSE), not null
#  ignore_reblog      :boolean          default(FALSE), not null
#  replies_policy     :integer          default("list"), not null
#  exclusive          :boolean          default(FALSE), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

class List < ApplicationRecord
  include Paginable

  PER_ACCOUNT_LIMIT = 50

  enum :replies_policy, { list: 0, followed: 1, none: 2 }, prefix: :show, validate: true

  belongs_to :account

  has_many :list_accounts, inverse_of: :list, dependent: :destroy
  has_many :accounts, through: :list_accounts
  has_many :active_accounts, -> { merge(ListAccount.active) }, through: :list_accounts, source: :account

  validates :title, presence: true

  validate :validate_account_lists_limit, on: :create

  before_destroy :clean_feed_manager

  scope :with_list_account, ->(account) { joins(:list_accounts).where(list_accounts: { account: }) }

  before_validation :normalize_keyword_groups

  validate :keywords_are_array_of_string_arrays

  private

  def validate_account_lists_limit
    errors.add(:base, I18n.t('lists.errors.limit')) if account.owned_lists.count >= PER_ACCOUNT_LIMIT
  end

  def clean_feed_manager
    FeedManager.instance.clean_feeds!(:list, [id])
  end

  def normalize_keyword_groups
    self.include_keywords = normalize_groups(include_keywords)
    self.exclude_keywords = normalize_groups(exclude_keywords)
  end

  # normalize nil, json a
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

  def keywords_are_array_of_string_arrays
    unless include_keywords.is_a?(Array) &&
           include_keywords.all? { |g| g.is_a?(Array) && g.all? { |s| s.is_a?(String) } }
      errors.add(:include_keywords, 'must be an array of string arrays')
    end

    unless exclude_keywords.is_a?(Array) &&
           exclude_keywords.all? { |g| g.is_a?(Array) && g.all? { |s| s.is_a?(String) } }
      errors.add(:exclude_keywords, 'must be an array of string arrays')
    end
  end
end
