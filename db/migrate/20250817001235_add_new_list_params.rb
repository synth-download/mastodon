class AddNewListParams < ActiveRecord::Migration[6.1]
  def change
    safety_assured { 
      add_column :lists, :include_keywords, :jsonb, default: [], null: false
      add_column :lists, :exclude_keywords, :jsonb, default: [], null: false
      add_column :lists, :with_media_only, :boolean, default: false, null: false
      add_column :lists, :ignore_reblog, :boolean, default: false, null: false
    }
  end
end
