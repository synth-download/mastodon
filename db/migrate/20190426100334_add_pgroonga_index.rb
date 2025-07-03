# frozen_string_literal: true

class AddPgroongaIndex < ActiveRecord::Migration[5.2]
  def change
    safety_assured { add_index :statuses, :text, using: :pgroonga }
  end
end
