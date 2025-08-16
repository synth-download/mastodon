# frozen_string_literal: true

require Rails.root.join('lib', 'mastodon', 'migration_helpers')

class AddAntennaElementsUniqueness < ActiveRecord::Migration[7.0]
  include Mastodon::MigrationHelpers

  disable_ddl_transaction!

  def change
    safety_assured do
      add_index :antenna_accounts, [:antenna_id, :account_id], unique: true
      add_index :antenna_domains, [:antenna_id, :name], unique: true
      add_index :antenna_tags, [:antenna_id, :tag_id], unique: true
    end
  end
end