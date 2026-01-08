# frozen_string_literal: true

class SearchService < BaseService
  QUOTE_EQUIVALENT_CHARACTERS = /[“”„«»「」『』《》]/

  def call(query, account, limit, options = {})
    @query     = query&.strip&.gsub(QUOTE_EQUIVALENT_CHARACTERS, '"')
    @account   = account
    @options   = options
    @limit     = limit.to_i
    @offset    = options[:type].blank? ? 0 : options[:offset].to_i
    @resolve   = options[:resolve] || false
    @following = options[:following] || false
    @query_fasp = options[:query_fasp] || false

    default_results.tap do |results|
      next if @query.blank? || @limit.zero?

      if url_query?
        results.merge!(url_resource_results) unless url_resource.nil? || @offset.positive? || (@options[:type].present? && url_resource_symbol != @options[:type].to_sym)
      elsif @query.present?
        results[:accounts] = perform_accounts_search! if account_searchable?
        results[:statuses] = perform_statuses_search! if status_searchable?
        results[:hashtags] = perform_hashtags_search! if hashtag_searchable?
      end
    end
  end

  private

  def perform_accounts_search!
    AccountSearchService.new.call(
      @query,
      @account,
      limit: @limit,
      resolve: @resolve,
      offset: @offset,
      use_searchable_text: true,
      following: @following,
      start_with_hashtag: @query.start_with?('#'),
      query_fasp: @options[:query_fasp]
    )
  end

  def perform_statuses_search!
    # select all public statuses and all statuses from the account the quried
    results = Status.where(visibility: :public, reblog_of_id: nil)
    results = results.or(Status.where(account_id: @account.id, reblog_of_id: nil)) if @account.present?

    flags, query = parse_search_flags

    unless query.strip.empty?
      text_matches = results.where('statuses.text &@~ ?', query).select(:id)
      media_matches = results.joins(:media_attachments).where('media_attachments.description &@~ ?', query).select('statuses.id')

      results = results.where(id: text_matches).or(results.where(id: media_matches))
    end

    # check if authed to resolve flags.
    if @account.present?
      if flags[:from].present?
        positive = flags[:from].reject { |f| f[:not] }
        negative = flags[:from].select { |f| f[:not] }

        accounts = positive.flat_map { |entry| resolve_account_ids(entry[:value]) }.uniq
        return Status.none if positive.any? && accounts.empty?

        results = results.where(account_id: accounts) if accounts.any?

        not_accounts = negative.flat_map { |entry| resolve_account_ids(entry[:value]) }.uniq
        results = results.where.not(account_id: not_accounts) if not_accounts.any?
      end

      if flags[:has].present?
        flags[:has].each do |entry|
          case entry[:value].downcase
          when 'media'
            op = entry[:not] ? '=' : '>'
            results = results.where("COALESCE(array_length(ordered_media_attachment_ids, 1), 0) #{op} 0")
          when 'poll'
            results = entry[:not] ? results.where(poll_id: nil) : results.where.not(poll_id: nil)
          end
        end
      end

      if flags[:is].present?
        flags[:is].each do |entry|
          case entry[:value].downcase
          when 'reply'
            results = results.where(reply: entry[:not] ? false : true)
          when 'sensitive'
            results = results.where(sensitive: entry[:not] ? false : true)
          end
        end
      end

      if flags[:language].present?
        positive = flags[:language].reject { |f| f[:not] }.map { |f| f[:value].downcase }
        negative = flags[:language].select { |f| f[:not] }.map { |f| f[:value].downcase }

        results = results.where(language: positive) if positive.any?
        results = results.where.not(language: negative) if negative.any?
      end
    end

    # legacy flags
    results = results.where(account_id: @options[:account_id]) if @options[:account_id].present?
    results = results.where('statuses.id > ?', @options[:min_id]) if @options[:min_id].present?
    results = results.where(statuses: { id: ...(@options[:max_id]) }) if @options[:max_id].present?

    if @account.present?
      blocked_ids = @account.blocking.select(:target_account_id)
      muted_ids = @account.muting.select(:target_account_id)

      results = results.where.not(account_id: blocked_ids) if blocked_ids.any?
      results = results.where.not(account_id: muted_ids) if muted_ids.any?

      blocked_domains = @account.domain_blocks.pluck(:domain)
      results = results.joins(:account).where.not(accounts: { domain: blocked_domains }) if blocked_domains.any?
    end

    results = results.distinct.limit(@limit * 2).offset(@offset)

    filtered = []
    results.each do |status|
      break if filtered.size >= @limit
      next if StatusFilter.new(status, @account).filtered?

      filtered << status
    end

    filtered
  end

  def resolve_account_ids(value)
    return Account.none if value.blank?

    v = value.to_s.strip

    return @account.id if v.downcase == 'me'

    if (m = v.match(/\A@?([^@]+)@(.+)\z/))
      return Account.where(username: m[1], domain: m[2]).pluck(:id)
    end

    username = v.sub(/\A@/, '')
    Account.where(username: username, domain: nil).pluck(:id)
  end

  def parse_search_flags
    query = @query.to_s.dup
    flags = Hash.new { |h, k| h[k] = [] }

    while (m = query.match(/(-?)(\w+):(?:"([^"]+)"|(\S+))/))
      flags[m[2].downcase.to_sym] << { not: m[1] == '-', value: m[3] || m[4] }
      query.sub!(m[0], '')
    end
    [flags, query]
  end

  def perform_hashtags_search!
    TagSearchService.new.call(
      @query,
      limit: @limit,
      offset: @offset,
      exclude_unreviewed: @options[:exclude_unreviewed]
    )
  end

  def default_results
    { accounts: [], hashtags: [], statuses: [] }
  end

  def url_query?
    @resolve && %r{\Ahttps?://}.match?(@query)
  end

  def url_resource_results
    { url_resource_symbol => [url_resource] }
  end

  def url_resource
    @url_resource ||= ResolveURLService.new.call(@query, on_behalf_of: @account)
  end

  def url_resource_symbol
    url_resource.class.name.downcase.pluralize.to_sym
  end

  def status_searchable?
    status_search? && @account.present?
  end

  def account_searchable?
    account_search?
  end

  def hashtag_searchable?
    hashtag_search?
  end

  def account_search?
    @options[:type].blank? || @options[:type] == 'accounts'
  end

  def hashtag_search?
    @options[:type].blank? || @options[:type] == 'hashtags'
  end

  def status_search?
    @options[:type].blank? || @options[:type] == 'statuses'
  end
end
