# frozen_string_literal: true

Fabricator(:antenna_tag) do
  antenna { Fabricate.build(:antenna) }
  tag { Fabricate.build(:tag) }
  exclude false
end