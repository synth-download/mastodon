# frozen_string_literal: true

class AddPgroongaSpoilerIndex < ActiveRecord::Migration[8.0]
  def change
    safety_assured { add_index :statuses, :spoiler_text, using: :pgroonga }
  end
end
