# frozen_string_literal: true

class AddMediaPgroongaIndex < ActiveRecord::Migration[8.0]
  def change
    safety_assured { add_index :media_attachments, :description, using: :pgroonga }
  end
end
