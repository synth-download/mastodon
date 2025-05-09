# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_04_28_095029) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgroonga"
  enable_extension "pg_catalog.plpgsql"

  create_table "account_aliases", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "acct", default: "", null: false
    t.string "uri", default: "", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["account_id", "uri"], name: "index_account_aliases_on_account_id_and_uri", unique: true
  end

  # ...（中略：他のテーブル定義や内容は変更せずそのまま）...

end
