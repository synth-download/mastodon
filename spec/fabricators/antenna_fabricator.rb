# frozen_string_literal: true

Fabricator(:antenna) do
  account { Fabricate.build(:account) }
  title 'MyString'
  list_id 0
end