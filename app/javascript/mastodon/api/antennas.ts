import {
  apiRequestPost,
  apiRequestPut,
  apiRequestGet,
  apiRequestDelete,
} from 'mastodon/api';
import type { ApiAccountJSON } from 'mastodon/api_types/accounts';
import type { ApiAntennaJSON } from 'mastodon/api_types/antennas';

export const apiCreate = (antenna: Partial<ApiAntennaJSON>) =>
  apiRequestPost<ApiAntennaJSON>('v1/antennas', antenna);

export const apiUpdate = (antenna: Partial<ApiAntennaJSON>) =>
  apiRequestPut<ApiAntennaJSON>(`v1/antennas/${antenna.id}`, antenna);

export const apiGetAntennas = () =>
  apiRequestGet<ApiAntennaJSON[]>('v1/antennas');

export const apiGetAccounts = (antennaId: string) =>
  apiRequestGet<ApiAccountJSON[]>(`v1/antennas/${antennaId}/accounts`, {
    limit: 0,
  });

export const apiGetExcludeAccounts = (antennaId: string) =>
  apiRequestGet<ApiAccountJSON[]>(`v1/antennas/${antennaId}/exclude_accounts`, {
    limit: 0,
  });

export const apiGetDomains = (antennaId: string) =>
  apiRequestGet<{ domains: string[]; exclude_domains: string[] }>(
    `v1/antennas/${antennaId}/domains`,
    {
      limit: 0,
    },
  );

export const apiAddDomain = (antennaId: string, domain: string) =>
  apiRequestPost(`v1/antennas/${antennaId}/domains`, {
    domains: [domain],
  });

export const apiRemoveDomain = (antennaId: string, domain: string) =>
  apiRequestDelete(`v1/antennas/${antennaId}/domains`, {
    domains: [domain],
  });

export const apiAddExcludeDomain = (antennaId: string, domain: string) =>
  apiRequestPost(`v1/antennas/${antennaId}/exclude_domains`, {
    domains: [domain],
  });

export const apiRemoveExcludeDomain = (antennaId: string, domain: string) =>
  apiRequestDelete(`v1/antennas/${antennaId}/exclude_domains`, {
    domains: [domain],
  });

export const apiGetTags = (antennaId: string) =>
  apiRequestGet<{ tags: string[]; exclude_tags: string[] }>(
    `v1/antennas/${antennaId}/tags`,
    {
      limit: 0,
    },
  );

export const apiAddTag = (antennaId: string, tag: string) =>
  apiRequestPost(`v1/antennas/${antennaId}/tags`, {
    tags: [tag],
  });

export const apiRemoveTag = (antennaId: string, tag: string) =>
  apiRequestDelete(`v1/antennas/${antennaId}/tags`, {
    tags: [tag],
  });

export const apiAddExcludeTag = (antennaId: string, tag: string) =>
  apiRequestPost(`v1/antennas/${antennaId}/exclude_tags`, {
    tags: [tag],
  });

export const apiRemoveExcludeTag = (antennaId: string, tag: string) =>
  apiRequestDelete(`v1/antennas/${antennaId}/exclude_tags`, {
    tags: [tag],
  });

export const apiGetKeywords = (antennaId: string) =>
  apiRequestGet<{ keywords: string[]; exclude_keywords: string[] }>(
    `v1/antennas/${antennaId}/keywords`,
    {
      limit: 0,
    },
  );

export const apiAddKeyword = (antennaId: string, keyword: string) =>
  apiRequestPost(`v1/antennas/${antennaId}/keywords`, {
    keywords: [keyword],
  });

export const apiRemoveKeyword = (antennaId: string, keyword: string) =>
  apiRequestDelete(`v1/antennas/${antennaId}/keywords`, {
    keywords: [keyword],
  });

export const apiAddExcludeKeyword = (antennaId: string, keyword: string) =>
  apiRequestPost(`v1/antennas/${antennaId}/exclude_keywords`, {
    keywords: [keyword],
  });

export const apiRemoveExcludeKeyword = (antennaId: string, keyword: string) =>
  apiRequestDelete(`v1/antennas/${antennaId}/exclude_keywords`, {
    keywords: [keyword],
  });

export const apiGetAccountAntennas = (accountId: string) =>
  apiRequestGet<ApiAntennaJSON[]>(`v1/accounts/${accountId}/antennas`);

export const apiAddAccountToAntenna = (antennaId: string, accountId: string) =>
  apiRequestPost(`v1/antennas/${antennaId}/accounts`, {
    account_ids: [accountId],
  });

export const apiRemoveAccountFromAntenna = (
  antennaId: string,
  accountId: string,
) =>
  apiRequestDelete(`v1/antennas/${antennaId}/accounts`, {
    account_ids: [accountId],
  });

export const apiGetExcludeAccountAntennas = (accountId: string) =>
  apiRequestGet<ApiAntennaJSON[]>(`v1/accounts/${accountId}/exclude_antennas`);

export const apiAddExcludeAccountToAntenna = (
  antennaId: string,
  accountId: string,
) =>
  apiRequestPost(`v1/antennas/${antennaId}/exclude_accounts`, {
    account_ids: [accountId],
  });

export const apiRemoveExcludeAccountFromAntenna = (
  antennaId: string,
  accountId: string,
) =>
  apiRequestDelete(`v1/antennas/${antennaId}/exclude_accounts`, {
    account_ids: [accountId],
  });