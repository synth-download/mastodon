# frozen_string_literal: true

class ChangeAntennasListToNullable < ActiveRecord::Migration[6.1]
  def up
    safety_assured do
      remove_foreign_key :antennas, :lists
    end
  end

  def down
    safety_assured do
      add_foreign_key :antennas, :lists
    end
  end
end