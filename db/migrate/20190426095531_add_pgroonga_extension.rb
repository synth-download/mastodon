# frozen_string_literal: true

class AddPgroongaExtension < ActiveRecord::Migration[5.2]
  def change
    enable_extension 'pgroonga'
  end
end
