# frozen_string_literal: true

class AddDissubscribableToAccounts < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      add_column :antennas, :with_media_only, :boolean, null: false, default: false
      add_index :antennas, :with_media_only
      add_column :accounts, :dissubscribable, :boolean, null: false, default: false
    end
  end
end