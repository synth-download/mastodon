import type { ApiStatusReactionJSON } from 'flavours/glitch/api_types/reaction';

export interface StatusReaction extends Omit<ApiStatusReactionJSON, 'account'> {
  account: string;
}

export type StatusReactionMap = Immutable.Map<string, unknown>;
