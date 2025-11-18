import { useCallback, useState, useEffect } from 'react';

import { defineMessages, useIntl, FormattedMessage } from 'react-intl';

import { Helmet } from 'react-helmet';
import { useParams, useHistory, Link } from 'react-router-dom';

import { isFulfilled } from '@reduxjs/toolkit';

import Toggle from 'react-toggle';

import ChevronRightIcon from '@/material-icons/400-24px/chevron_right.svg?react';
import ListAltIcon from '@/material-icons/400-24px/list_alt.svg?react';
import CloseIcon from '@/material-icons/400-24px/close.svg?react';
import { fetchList } from 'flavours/glitch/actions/lists';
import { createList, updateList } from 'flavours/glitch/actions/lists_typed';
import { apiGetAccounts } from 'flavours/glitch/api/lists';
import type { ApiAccountJSON } from 'flavours/glitch/api_types/accounts';
import type { RepliesPolicyType } from 'flavours/glitch/api_types/lists';
import { Avatar } from 'flavours/glitch/components/avatar';
import { AvatarGroup } from 'flavours/glitch/components/avatar_group';
import { Column } from 'flavours/glitch/components/column';
import { ColumnHeader } from 'flavours/glitch/components/column_header';
import { Icon } from 'flavours/glitch/components/icon';
import { LoadingIndicator } from 'flavours/glitch/components/loading_indicator';
import type { List } from 'flavours/glitch/models/list';
import { useAppDispatch, useAppSelector } from 'flavours/glitch/store';

import { messages as membersMessages } from './members';

const messages = defineMessages({
  edit: { id: 'column.edit_list', defaultMessage: 'Edit list' },
  create: { id: 'column.create_list', defaultMessage: 'Create list' },
});

const KeywordPills: React.FC<{
  keywords: string[];
  onRemove: (keyword: string) => void;
}> = ({ keywords, onRemove }) => {
  if (keywords.length === 0) return null;

  return (
    <div className='keyword-pills'>
      {keywords.map((keyword, index) => (
        <div key={index} className='keyword-pill'>
          <span className='keyword-pill__text'>{keyword}</span>
          <button
            type='button'
            className='keyword-pill__remove'
            onClick={() => onRemove(keyword)}
            aria-label={`Remove ${keyword}`}
          >
            <Icon id='close' icon={CloseIcon} size={12} />
          </button>
        </div>
      ))}
    </div>
  );
};

const REGEX_PATTER_REGEX = RegExp(/^\/(.+)\/$/);

const validateKeyword = (
  keyword: string,
): { valid: boolean; error?: string } => {
  const trimmed = keyword.trim();

  if (!trimmed) {
    return { valid: false, error: 'Keyword cannot be empty' };
  }

  if (REGEX_PATTER_REGEX.test(trimmed)) {
    try {
      new RegExp(trimmed + 'i');
      return { valid: true };
    } catch (e) {
      return {
        valid: false,
        error: `Invalid regex pattern: ${e instanceof Error ? e.message : 'Unknown error'}`,
      };
    }
  }

  return { valid: true };
};

const KeywordInput: React.FC<{
  label: React.ReactNode;
  id: string;
  value: string[];
  onChange: (keywords: string[]) => void;
  placeholder?: string;
}> = ({ label, id, value, onChange, placeholder }) => {
  const [inputValue, setInputValue] = useState('');
  const [error, setError] = useState<string | null>(null);

  const handleInputChange = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      setInputValue(e.target.value);
      setError(null);
    },
    [],
  );

  const commitKeyword = useCallback(() => {
    const newKeyword = inputValue.trim();
    const validation = validateKeyword(newKeyword);

    if (!validation.valid) {
      setError(validation.error || 'Invalid keyword');
      return;
    }

    if (newKeyword && !value.includes(newKeyword)) {
      onChange([...value, newKeyword]);
      setInputValue('');
      setError(null);
    }
  }, [inputValue, value, onChange]);

  const handleSubmit = useCallback(
    (e: React.FormEvent) => {
      e.preventDefault();
      commitKeyword();
    },
    [commitKeyword],
  );

  const handleInputKeyDown = useCallback(
    (e: React.KeyboardEvent<HTMLInputElement>) => {
      if (e.key === 'Enter') {
        e.preventDefault();
        commitKeyword();
      } else if (
        e.key === 'Backspace' &&
        inputValue === '' &&
        value.length > 0
      ) {
        const lastKeyword = value[value.length - 1];
        onChange(value.slice(0, -1));
        if (lastKeyword) {
          e.preventDefault();
          setInputValue(lastKeyword);
        }
      }
    },
    [inputValue, value, onChange, commitKeyword],
  );

  const handleRemoveKeyword = useCallback(
    (keywordToRemove: string) => {
      onChange(value.filter((keyword) => keyword !== keywordToRemove));
    },
    [value, onChange],
  );

  return (
    <div className='input with_label'>
      <div className='label_input'>
        <label htmlFor={id}>{label}</label>
        <form
          onSubmit={handleSubmit}
          className='label_input__wrapper keyword-input-wrapper'
          noValidate
        >
          <KeywordPills keywords={value} onRemove={handleRemoveKeyword} />
          <input
            id={id}
            type='text'
            value={inputValue}
            onChange={handleInputChange}
            onKeyDown={handleInputKeyDown}
            placeholder={placeholder || 'Type a keyword and press Enter to add'}
            inputMode='text'
            enterKeyHint='done'
            autoComplete='off'
            aria-label={typeof label === 'string' ? label : undefined}
            className={`${error && 'keyword-input-wrapper__input_error'} keyword-input-wrapper__input`}
          />
          {error && <p className='keyword-input-wrapper__error'>{error}</p>}
          <button type='submit' style={{ display: 'none' }} aria-hidden />
        </form>
      </div>
    </div>
  );
};

const MembersLink: React.FC<{
  id: string;
}> = ({ id }) => {
  const intl = useIntl();
  const [avatarCount, setAvatarCount] = useState(0);
  const [avatarAccounts, setAvatarAccounts] = useState<ApiAccountJSON[]>([]);

  useEffect(() => {
    void apiGetAccounts(id)
      .then((data) => {
        setAvatarCount(data.length);
        setAvatarAccounts(data.slice(0, 3));
      })
      .catch(() => {
        // Nothing
      });
  }, [id]);

  return (
    <Link to={`/lists/${id}/members`} className='app-form__link'>
      <div className='app-form__link__text'>
        <strong>
          {intl.formatMessage(membersMessages.manageMembers)}
          <Icon id='chevron_right' icon={ChevronRightIcon} />
        </strong>
        <FormattedMessage
          id='lists.list_members_count'
          defaultMessage='{count, plural, one {# member} other {# members}}'
          values={{ count: avatarCount }}
        />
      </div>

      <AvatarGroup compact>
        {avatarAccounts.map((a) => (
          <Avatar key={a.id} account={a} size={30} />
        ))}
      </AvatarGroup>
    </Link>
  );
};

const NewList: React.FC<{ list?: List | null }> = ({ list }) => {
  const dispatch = useAppDispatch();
  const history = useHistory();

  const {
    id,
    title: initialTitle = '',
    exclusive: initialExclusive = false,
    replies_policy: initialRepliesPolicy = 'list',
  } = list ?? {};

  const [title, setTitle] = useState(initialTitle);
  const [keywords, setKeywords] = useState<string[]>([]);
  const [excludeKeywords, setExcludeKeywords] = useState<string[]>([]);
  const [withMediaOnly, setWithMediaOnly] = useState(false);
  const [ignoreReblog, setIgnoreReblog] = useState(false);
  const [exclusive, setExclusive] = useState(initialExclusive);
  const [repliesPolicy, setRepliesPolicy] =
    useState<RepliesPolicyType>(initialRepliesPolicy);
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    if (id) {
      dispatch(fetchList(id));
    }
  }, [dispatch, id]);

  useEffect(() => {
    if (id && list) {
      setTitle(list.title);
      setKeywords(list.include_keywords);
      setExcludeKeywords(list.exclude_keywords);
      setWithMediaOnly(list.with_media_only);
      setIgnoreReblog(list.ignore_reblog);
      setExclusive(list.exclusive);
      setRepliesPolicy(list.replies_policy);
    }
  }, [id, list]);

  const handleTitleChange = useCallback(
    ({ target: { value } }: React.ChangeEvent<HTMLInputElement>) => {
      setTitle(value);
    },
    [setTitle],
  );

  const handleKeywordsChange = useCallback(
    (newKeywords: string[]) => {
      setKeywords(newKeywords);
    },
    [setKeywords],
  );

  const handleExcludeKeywordsChange = useCallback(
    (newKeywords: string[]) => {
      setExcludeKeywords(newKeywords);
    },
    [setExcludeKeywords],
  );

  const handleWithMediaOnlyChange = useCallback(
    ({ target: { checked } }: React.ChangeEvent<HTMLInputElement>) => {
      setWithMediaOnly(checked);
    },
    [setWithMediaOnly],
  );

  const handleIgnoreReblogChange = useCallback(
    ({ target: { checked } }: React.ChangeEvent<HTMLInputElement>) => {
      setIgnoreReblog(checked);
    },
    [setIgnoreReblog],
  );

  const handleExclusiveChange = useCallback(
    ({ target: { checked } }: React.ChangeEvent<HTMLInputElement>) => {
      setExclusive(checked);
    },
    [setExclusive],
  );

  const handleRepliesPolicyChange = useCallback(
    ({ target: { value } }: React.ChangeEvent<HTMLSelectElement>) => {
      setRepliesPolicy(value as RepliesPolicyType);
    },
    [setRepliesPolicy],
  );

  const handleSubmit = useCallback(() => {
    setSubmitting(true);

    if (id) {
      void dispatch(
        updateList({
          id,
          title,
          with_media_only: withMediaOnly,
          ignore_reblog: ignoreReblog,
          exclusive,
          include_keywords: keywords,
          exclude_keywords: excludeKeywords,
          replies_policy: repliesPolicy,
        }),
      ).then(() => {
        setSubmitting(false);
        return '';
      });
    } else {
      void dispatch(
        createList({
          title,
          with_media_only: withMediaOnly,
          ignore_reblog: ignoreReblog,
          exclusive,
          include_keywords: keywords,
          exclude_keywords: excludeKeywords,
          replies_policy: repliesPolicy,
        }),
      ).then((result) => {
        setSubmitting(false);

        if (isFulfilled(result)) {
          history.replace(`/lists/${result.payload.id}/edit`);
          history.push(`/lists/${result.payload.id}/members`);
        }

        return '';
      });
    }
  }, [
    history,
    dispatch,
    setSubmitting,
    id,
    title,
    withMediaOnly,
    ignoreReblog,
    exclusive,
    repliesPolicy,
    keywords,
    excludeKeywords,
  ]);

  return (
    <form className='simple_form app-form' onSubmit={handleSubmit}>
      <div className='fields-group'>
        <div className='input with_label'>
          <div className='label_input'>
            <label htmlFor='list_title'>
              <FormattedMessage
                id='lists.list_name'
                defaultMessage='List name'
              />
            </label>

            <div className='label_input__wrapper'>
              <input
                id='list_title'
                type='text'
                value={title}
                onChange={handleTitleChange}
                maxLength={30}
                required
                placeholder=' '
              />
            </div>
          </div>
        </div>
      </div>

      <div className='fields-group'>
        <div className='input with_label'>
          <div className='label_input'>
            <label htmlFor='list_replies_policy'>
              <FormattedMessage
                id='lists.show_replies_to'
                defaultMessage='Include replies from list members to'
              />
            </label>

            <div className='label_input__wrapper'>
              <select
                id='list_replies_policy'
                value={repliesPolicy}
                onChange={handleRepliesPolicyChange}
              >
                <FormattedMessage
                  id='lists.replies_policy.none'
                  defaultMessage='No one'
                >
                  {(msg) => <option value='none'>{msg}</option>}
                </FormattedMessage>
                <FormattedMessage
                  id='lists.replies_policy.list'
                  defaultMessage='Members of the list'
                >
                  {(msg) => <option value='list'>{msg}</option>}
                </FormattedMessage>
                <FormattedMessage
                  id='lists.replies_policy.followed'
                  defaultMessage='Any followed user'
                >
                  {(msg) => <option value='followed'>{msg}</option>}
                </FormattedMessage>
              </select>
            </div>
          </div>
        </div>
      </div>

          {id && (
            <div className='fields-group'>
              <MembersLink id={id} />
            </div>
          )}

          <div className='fields-group'>
            <KeywordInput
              label={
                <FormattedMessage
                  id='lists.include_keywords'
                  defaultMessage='Include keywords'
                />
              }
              id='include_keywords'
              value={keywords}
              onChange={handleKeywordsChange}
              placeholder={intl.formatMessage({
                id: 'lists.include_keywords.placeholder',
                defaultMessage: 'Add keywords to include (press Enter to add)',
              })}
            />
          </div>

          <div className='fields-group'>
            <KeywordInput
              label={
                <FormattedMessage
                  id='lists.exclude_keywords'
                  defaultMessage='Exclude keywords'
                />
              }
              id='exclude_keywords'
              value={excludeKeywords}
              onChange={handleExcludeKeywordsChange}
              placeholder={intl.formatMessage({
                id: 'lists.exclude_keywords.placeholder',
                defaultMessage: 'Add keywords to exclude (press Enter to add)',
              })}
            />
          </div>

          <div className='fields-group'>
            {/* eslint-disable-next-line jsx-a11y/label-has-associated-control */}
            <label className='app-form__toggle'>
              <div className='app-form__toggle__label'>
                <strong>
                  <FormattedMessage
                    id='lists.with_media_only'
                    defaultMessage='Media only'
                  />
                </strong>
                <span className='hint'>
                  <FormattedMessage
                    id='lists.with_media_only_hint'
                    defaultMessage='Only posts with media will be added to the list.'
                  />
                </span>
              </div>

              <div className='app-form__toggle__toggle'>
                <div>
                  <Toggle
                    checked={withMediaOnly}
                    onChange={handleWithMediaOnlyChange}
                  />
                </div>
              </div>
            </label>
          </div>

          <div className='fields-group'>
            {/* eslint-disable-next-line jsx-a11y/label-has-associated-control */}
            <label className='app-form__toggle'>
              <div className='app-form__toggle__label'>
                <strong>
                  <FormattedMessage
                    id='lists.ignore_reblog'
                    defaultMessage='Exclude boosts'
                  />
                </strong>
                <span className='hint'>
                  <FormattedMessage
                    id='lists.ignore_reblog_hint'
                    defaultMessage='Boosts will be excluded from this list.'
                  />
                </span>
              </div>

              <div className='app-form__toggle__toggle'>
                <div>
                  <Toggle
                    checked={ignoreReblog}
                    onChange={handleIgnoreReblogChange}
                  />
                </div>
              </div>
            </label>
          </div>

      <div className='fields-group'>
        {/* eslint-disable-next-line jsx-a11y/label-has-associated-control */}
        <label className='app-form__toggle'>
          <div className='app-form__toggle__label'>
            <strong>
              <FormattedMessage
                id='lists.exclusive'
                defaultMessage='Hide members in Home'
              />
            </strong>
            <span className='hint'>
              <FormattedMessage
                id='lists.exclusive_hint'
                defaultMessage='If someone is on this list, hide them in your Home feed to avoid seeing their posts twice.'
              />
            </span>
          </div>

          <div className='app-form__toggle__toggle'>
            <div>
              <Toggle checked={exclusive} onChange={handleExclusiveChange} />
            </div>
          </div>
        </label>
      </div>

      <div className='actions'>
        <button className='button' type='submit'>
          {submitting ? (
            <LoadingIndicator />
          ) : id ? (
            <FormattedMessage id='lists.save' defaultMessage='Save' />
          ) : (
            <FormattedMessage id='lists.create' defaultMessage='Create' />
          )}
        </button>
      </div>
    </form>
  );
};

const NewListWrapper: React.FC<{
  multiColumn?: boolean;
}> = ({ multiColumn }) => {
  const intl = useIntl();
  const dispatch = useAppDispatch();
  const { id } = useParams<{ id?: string }>();
  const list = useAppSelector((state) =>
    id ? state.lists.get(id) : undefined,
  );

  useEffect(() => {
    if (id) {
      dispatch(fetchList(id));
    }
  }, [dispatch, id]);

  const isLoading = id && !list;

  return (
    <Column
      bindToDocument={!multiColumn}
      label={intl.formatMessage(id ? messages.edit : messages.create)}
    >
      <ColumnHeader
        title={intl.formatMessage(id ? messages.edit : messages.create)}
        icon='list-ul'
        iconComponent={ListAltIcon}
        multiColumn={multiColumn}
        showBackButton
      />

      <div className='scrollable'>
        {isLoading ? <LoadingIndicator /> : <NewList list={list} />}
      </div>

      <Helmet>
        <title>
          {intl.formatMessage(id ? messages.edit : messages.create)}
        </title>
        <meta name='robots' content='noindex' />
      </Helmet>
    </Column>
  );
};

// eslint-disable-next-line import/no-default-export
export default NewListWrapper;
