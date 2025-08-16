# frozen_string_literal: true

Fabricator(:antenna_domain) do
  antenna { Fabricate.build(:antenna) }
  name 'example.com'
  exclude false
end