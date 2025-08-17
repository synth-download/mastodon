import type { RecordOf } from 'immutable';
import { Record } from 'immutable';

import type { ApiListJSON } from 'flavours/glitch/api_types/lists';

type ListShape = Required<ApiListJSON>; // no changes from server shape
export type List = RecordOf<ListShape>;

const ListFactory = Record<ListShape>({
  id: '',
  title: '',
  include_keywords: [[]],
  exclude_keywords: [[]],
  with_media_only: false,
  ignore_reblog: false,
  exclusive: false,
  replies_policy: 'list',
});

export function createList(attributes: Partial<ListShape>) {
  return ListFactory(attributes);
}
