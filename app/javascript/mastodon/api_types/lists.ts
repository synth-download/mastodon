// See app/serializers/rest/list_serializer.rb

export type RepliesPolicyType = 'list' | 'followed' | 'none';

export interface ApiListJSON {
  id: string;
  title: string;
  media_only: boolean;
  ignore_reblog: boolean;
  exclusive: boolean;
  replies_policy: RepliesPolicyType;
  include_keywords: string[][];
  exclude_keywords: string[][];
}
