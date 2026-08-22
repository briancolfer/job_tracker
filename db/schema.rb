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

ActiveRecord::Schema[8.1].define(version: 2026_08_22_000000) do
  create_table "contacts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.integer "job_application_id", null: false
    t.string "linkedin_url"
    t.string "name"
    t.text "notes"
    t.string "phone"
    t.integer "role"
    t.datetime "updated_at", null: false
    t.index ["job_application_id"], name: "index_contacts_on_job_application_id"
  end

  create_table "follow_ups", force: :cascade do |t|
    t.boolean "completed"
    t.datetime "created_at", null: false
    t.string "description"
    t.date "due_date"
    t.integer "job_application_id", null: false
    t.datetime "updated_at", null: false
    t.index ["job_application_id"], name: "index_follow_ups_on_job_application_id"
  end

  create_table "interview_stages", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.integer "job_application_id", null: false
    t.text "notes"
    t.integer "outcome"
    t.datetime "scheduled_at"
    t.integer "stage_type"
    t.datetime "updated_at", null: false
    t.index ["job_application_id"], name: "index_interview_stages_on_job_application_id"
  end

  create_table "job_applications", force: :cascade do |t|
    t.date "apply_date"
    t.string "company"
    t.datetime "created_at", null: false
    t.integer "days_in_office"
    t.string "job_posting_url"
    t.string "job_type"
    t.string "location"
    t.text "notes"
    t.string "role_title"
    t.string "source"
    t.integer "status"
    t.datetime "updated_at", null: false
  end

  create_table "job_statuses", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.boolean "default", default: false, null: false
    t.string "label", null: false
    t.boolean "terminal", default: false, null: false
    t.datetime "updated_at", null: false
    t.integer "value", null: false
    t.index ["code"], name: "index_job_statuses_on_code", unique: true
    t.index ["default"], name: "index_job_statuses_on_default", unique: true, where: "\"default\" = 1"
    t.index ["value"], name: "index_job_statuses_on_value", unique: true
  end

  add_foreign_key "contacts", "job_applications"
  add_foreign_key "follow_ups", "job_applications"
  add_foreign_key "interview_stages", "job_applications"
end
