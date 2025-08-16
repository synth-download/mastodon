import { apiCreate, apiGetAntennas, apiUpdate } from 'mastodon/api/antennas';
import type { Antenna } from 'mastodon/models/antenna';
import { createDataLoadingThunk } from 'mastodon/store/typed_functions';

export const createAntenna = createDataLoadingThunk(
  'antenna/create',
  (antenna: Partial<Antenna>) => apiCreate(antenna),
);

export const updateAntenna = createDataLoadingThunk(
  'antenna/update',
  (antenna: Partial<Antenna>) => apiUpdate(antenna),
);

export const fetchAntennas = createDataLoadingThunk('antennas/fetch', () =>
  apiGetAntennas(),
);