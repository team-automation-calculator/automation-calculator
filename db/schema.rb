# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20180302065202) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "automation_scenarios", force: :cascade do |t|
    t.string "owner_type"
    t.bigint "owner_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_type", "owner_id"], name: "index_automation_scenarios_on_owner_type_and_owner_id"
  end

  create_table "solutions", force: :cascade do |t|
    t.integer "initial_cost"
    t.integer "iteration_cost"
    t.integer "iteration_count"
    t.bigint "automation_scenario_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["automation_scenario_id"], name: "index_solutions_on_automation_scenario_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.string "provider"
    t.string "uid"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "visitors", force: :cascade do |t|
    t.string "ip"
    t.string "uuid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uuid"], name: "index_visitors_on_uuid", unique: true
  end

  add_foreign_key "solutions", "automation_scenarios"
end
