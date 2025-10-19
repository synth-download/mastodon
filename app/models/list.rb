# frozen_string_literal: true

# == Schema Information
#
# Table name: lists
#
#  id               :bigint(8)        not null, primary key
#  exclude_keywords :jsonb            not null
#  exclusive        :boolean          default(FALSE), not null
#  ignore_reblog    :boolean          default(FALSE), not null
#  include_keywords :jsonb            not null
#  replies_policy   :integer          default("list"), not null
#  title            :string           default(""), not null
#  with_media_only  :boolean          default(FALSE), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :bigint(8)        not null
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
  validate :keywords_are_arrays_of_strings
  after_save :clear_keyword_cache

  scope :with_list_account, ->(account) { joins(:list_accounts).where(list_accounts: { account: }) }

  def matches_any_keyword?(text, compiled_keywords)
    simple_keywords, regexes = compiled_keywords
    return true if simple_keywords.any? { |keyword| text.include?(keyword) }
    regexes.any? { |regex| regex.match?(text) }
  end

  def compiled_include_keywords
    @compiled_include_keywords ||= compile_keywords(include_keywords)
  end

  def compiled_exclude_keywords
    @compiled_exclude_keywords ||= compile_keywords(exclude_keywords)
  end

  private

  def validate_account_lists_limit
    errors.add(:base, I18n.t('lists.errors.limit')) if account.owned_lists.count >= PER_ACCOUNT_LIMIT
  end

  def clean_feed_manager
    FeedManager.instance.clean_feeds!(:list, [id])
  end

  def compile_keywords(keywords)
    simple_keywords = []
    regexes = []

    keywords.each do |keyword|
      if keyword.start_with?('/') && keyword.end_with?('/') && keyword.length > 2
        pattern = keyword[1..-2]
        begin
          regexes << Regexp.new(pattern, Regexp::IGNORECASE)
        rescue RegexpError => e
          Rails.logger.error "Invalid regex pattern in list #{id}: #{pattern} - #{e.message}"
          simple_keywords << keyword
        end
      else
        simple_keywords << keyword.downcase
      end
    end

    [simple_keywords, regexes]
  end

  def clear_keyword_cache
    @compiled_include_keywords = nil
    @compiled_exclude_keywords = nil
  end

  def keywords_are_arrays_of_strings
    unless include_keywords.is_a?(Array) && include_keywords.all? { |kw| kw.is_a?(String) }
      errors.add(:include_keywords, 'must be an array of strings')
    end

    unless exclude_keywords.is_a?(Array) && exclude_keywords.all? { |kw| kw.is_a?(String) }
      errors.add(:exclude_keywords, 'must be an array of strings')
    end
  end
end
