# frozen_string_literal: true

class CreateAntennas < ActiveRecord::Migration[6.1]
  def change
    create_table :antennas do |t|
      t.belongs_to :account, null: false, foreign_key: { on_delete: :cascade }
      t.belongs_to :list, null: false, foreign_key: { on_delete: :cascade }
      t.string :title, null: false, default: ''
      t.jsonb :keywords
      t.jsonb :exclude_keywords
      t.boolean :any_domains, null: false, default: true, index: true
      t.boolean :any_tags, null: false, default: true, index: true
      t.boolean :any_accounts, null: false, default: true, index: true
      t.boolean :any_keywords, null: false, default: true, index: true
      t.boolean :available, null: false, default: true, index: true
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.datetime :expires_at
    end
    create_table :antenna_domains do |t|
      t.belongs_to :antenna, null: false, foreign_key: { on_delete: :cascade }
      t.string :name, index: true
      t.boolean :exclude, null: false, default: false, index: true
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end
    create_table :antenna_tags do |t|
      t.belongs_to :antenna, null: false, foreign_key: { on_delete: :cascade }
      t.belongs_to :tag, null: false, foreign_key: { on_delete: :cascade }
      t.boolean :exclude, null: false, default: false, index: true
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end
    create_table :antenna_accounts do |t|
      t.belongs_to :antenna, null: false, foreign_key: { on_delete: :cascade }
      t.belongs_to :account, null: false, foreign_key: { on_delete: :cascade }
      t.boolean :exclude, null: false, default: false, index: true
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end
  end
end