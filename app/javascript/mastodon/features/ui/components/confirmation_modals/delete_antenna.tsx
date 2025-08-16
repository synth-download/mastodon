import { useCallback } from 'react';

import { defineMessages, useIntl } from 'react-intl';

import { useHistory } from 'react-router';

import { deleteAntenna } from 'mastodon/actions/antennas';
import { removeColumn } from 'mastodon/actions/columns';
import { useAppDispatch } from 'mastodon/store';

import type { BaseConfirmationModalProps } from './confirmation_modal';
import { ConfirmationModal } from './confirmation_modal';

const messages = defineMessages({
  deleteAntennaTitle: {
    id: 'confirmations.delete_antenna.title',
    defaultMessage: 'Delete antenna?',
  },
  deleteAntennaMessage: {
    id: 'confirmations.delete_antenna.message',
    defaultMessage: 'Are you sure you want to permanently delete this antenna?',
  },
  deleteAntennaConfirm: {
    id: 'confirmations.delete_antenna.confirm',
    defaultMessage: 'Delete',
  },
});

export const ConfirmDeleteAntennaModal: React.FC<
  {
    antennaId: string;
    columnId: string;
  } & BaseConfirmationModalProps
> = ({ antennaId, columnId, onClose }) => {
  const intl = useIntl();
  const dispatch = useAppDispatch();
  const history = useHistory();

  const onConfirm = useCallback(() => {
    dispatch(deleteAntenna(antennaId));

    if (columnId) {
      dispatch(removeColumn(columnId));
    } else {
      history.push('/antennas');
    }
  }, [dispatch, history, columnId, antennaId]);

  return (
    <ConfirmationModal
      title={intl.formatMessage(messages.deleteAntennaTitle)}
      message={intl.formatMessage(messages.deleteAntennaMessage)}
      confirm={intl.formatMessage(messages.deleteAntennaConfirm)}
      onConfirm={onConfirm}
      onClose={onClose}
    />
  );
};