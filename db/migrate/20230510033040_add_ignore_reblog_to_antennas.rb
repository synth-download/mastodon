
# frozen_string_literal: true

class AddIgnoreReblogToAntennas < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      add_column :antennas, :ignore_reblog, :boolean, null: false, default: false
      add_index :antennas, :ignore_reblog
    end
  end
end