import { useCallback, useState, useEffect } from 'react';

import { defineMessages, useIntl, FormattedMessage } from 'react-intl';

import { Helmet } from 'react-helmet';
import { useParams, useHistory, Link } from 'react-router-dom';

import { isFulfilled } from '@reduxjs/toolkit';

import Toggle from 'react-toggle';

import ChevronRightIcon from '@/material-icons/400-24px/chevron_right.svg?react';
import ListAltIcon from '@/material-icons/400-24px/list_alt.svg?react';
import { fetchList } from 'mastodon/actions/lists';
import { createList, updateList } from 'mastodon/actions/lists_typed';
import { apiGetAccounts } from 'mastodon/api/lists';
import type { ApiAccountJSON } from 'mastodon/api_types/accounts';
import type { RepliesPolicyType } from 'mastodon/api_types/lists';
import { Avatar } from 'mastodon/components/avatar';
import { AvatarGroup } from 'mastodon/components/avatar_group';
import { Column } from 'mastodon/components/column';
import { ColumnHeader } from 'mastodon/components/column_header';
import { Icon } from 'mastodon/components/icon';
import { LoadingIndicator } from 'mastodon/components/loading_indicator';
import { useAppDispatch, useAppSelector } from 'mastodon/store';

import { messages as membersMessages } from './members';

const messages = defineMessages({
  edit: { id: 'column.edit_list', defaultMessage: 'Edit list' },
  create: { id: 'column.create_list', defaultMessage: 'Create list' },
});

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

const NewList: React.FC<{
  multiColumn?: boolean;
}> = ({ multiColumn }) => {
  const dispatch = useAppDispatch();
  const { id } = useParams<{ id?: string }>();
  const intl = useIntl();
  const history = useHistory();

  const list = useAppSelector((state) =>
    id ? state.lists.get(id) : undefined,
  );
  const [title, setTitle] = useState('');
  const [keywords, setKeywords] = useState('');
  const [excludeKeywords, setExcludeKeywords] = useState('');
  const [withMediaOnly, setWithMediaOnly] = useState(false);
  const [ignoreReblog, setIgnoreReblog] = useState(false);
  const [exclusive, setExclusive] = useState(false);
  const [repliesPolicy, setRepliesPolicy] = useState<RepliesPolicyType>('list');
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    if (id) {
      dispatch(fetchList(id));
    }
  }, [dispatch, id]);

  useEffect(() => {
    if (id && list) {
      setTitle(list.title);
      setKeywords(list.include_keywords.join('\n'));
      setExcludeKeywords(list.exclude_keywords.join('\n'));
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
    ({ target: { value } }: React.ChangeEvent<HTMLInputElement>) => {
      setKeywords(value);
    },
    [setKeywords],
  );

  const handleExcludeKeywordsChange = useCallback(
    ({ target: { value } }: React.ChangeEvent<HTMLInputElement>) => {
      setExcludeKeywords(value);
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
    const include_keywords = keywords.split('\n')
      .map(line => line.trim())
      .filter(group => group.length > 0);
    const exclude_keywords = excludeKeywords.split('\n')
      .map(line => line.trim())
      .filter(group => group.length > 0);

    if (id) {
      void dispatch(
        updateList({
          id,
          title,
          with_media_only: withMediaOnly,
          ignore_reblog: ignoreReblog,
          exclusive,
          include_keywords,
          exclude_keywords,
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
          include_keywords,
          exclude_keywords,
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
    excludeKeywords
  ]);

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
            <div className='input with_label'>
              <div className='label_input'>
                <label htmlFor='include_keywords'>
                  <FormattedMessage
                    id='lists.include_keywords'
                    defaultMessage='Include keywords'
                  />
                </label>

                <div className='label_input__wrapper'>
                  <textarea
                    id='include_keywords'
                    value={keywords}
                    onChange={handleKeywordsChange}
                    placeholder=' '
                    rows="8"
                  />
                </div>
              </div>
            </div>
          </div>

          <div className='fields-group'>
            <div className='input with_label'>
              <div className='label_input'>
                <label htmlFor='exclude_keywords'>
                  <FormattedMessage
                    id='lists.exclude_keywords'
                    defaultMessage='Exclude keywords'
                  />
                </label>

                <div className='label_input__wrapper'>
                  <textarea
                    id='exclude_keywords'
                    value={excludeKeywords}
                    onChange={handleExcludeKeywordsChange}
                    placeholder=' '
                    rows="8"
                  />
                </div>
              </div>
            </div>
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
                  <Toggle
                    checked={exclusive}
                    onChange={handleExclusiveChange}
                  />
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
export default NewList;
