import type { Reducer } from '@reduxjs/toolkit';
import { Map as ImmutableMap } from 'immutable';

import {
  createAntenna,
  fetchAntennas,
  updateAntenna,
} from 'mastodon/actions/antennas_typed';
import type { ApiAntennaJSON } from 'mastodon/api_types/antennas';
import { createAntenna as createAntennaFromJSON } from 'mastodon/models/antenna';
import type { Antenna } from 'mastodon/models/antenna';

import {
  ANTENNA_FETCH_SUCCESS,
  ANTENNA_FETCH_FAIL,
  ANTENNA_DELETE_SUCCESS,
} from '../actions/antennas';

const initialState = ImmutableMap<string, Antenna | null>();
type State = typeof initialState;

const normalizeAntenna = (state: State, antenna: ApiAntennaJSON) =>
  state.set(antenna.id, createAntennaFromJSON(antenna));

const normalizeAntennas = (state: State, antennas: ApiAntennaJSON[]) => {
  antennas.forEach((antenna) => {
    state = normalizeAntenna(state, antenna);
  });

  return state;
};

export const antennasReducer: Reducer<State> = (
  state = initialState,
  action,
) => {
  if (
    createAntenna.fulfilled.match(action) ||
    updateAntenna.fulfilled.match(action)
  ) {
    return normalizeAntenna(state, action.payload);
  } else if (fetchAntennas.fulfilled.match(action)) {
    return normalizeAntennas(state, action.payload);
  } else {
    switch (action.type) {
      case ANTENNA_FETCH_SUCCESS:
        return normalizeAntenna(state, action.antenna as ApiAntennaJSON);
      case ANTENNA_DELETE_SUCCESS:
      case ANTENNA_FETCH_FAIL:
        return state.set(action.id as string, null);
      default:
        return state;
    }
  }
};