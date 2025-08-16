# frozen_string_literal: true

Fabricator(:antenna_account) do
  antenna { Fabricate.build(:antenna) }
  account { Fabricate.build(:account) }
  exclude false
end