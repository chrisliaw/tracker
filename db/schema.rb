# encoding: UTF-8
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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20150224141627) do

  create_table "attachments", :force => true do |t|
    t.string   "attachable_type"
    t.string   "attachable_id"
    t.integer  "attachment_class"
    t.string   "url"
    t.string   "project_id"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  create_table "change_logs", :force => true do |t|
    t.string   "table_name"
    t.string   "key"
    t.integer  "operation"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
    t.string   "changed_fields"
  end

  create_table "commits", :force => true do |t|
    t.string   "committables_type"
    t.string   "committables_id"
    t.string   "identifier"
    t.string   "vcs_reference"
    t.string   "vcs_diff"
    t.string   "vcs_info"
    t.string   "vcs_affected_files"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
    t.string   "repository_url"
    t.string   "dvcs_provider"
    t.string   "data_hash"
  end

  create_table "develement_types", :force => true do |t|
    t.string   "name"
    t.text     "desc"
    t.string   "state"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "develements", :force => true do |t|
    t.string   "identifier"
    t.string   "project_id"
    t.string   "name"
    t.text     "desc"
    t.string   "code"
    t.string   "state"
    t.integer  "develement_type_id"
    t.string   "schedule_id"
    t.string   "created_by"
    t.string   "variance_parent_id"
    t.string   "variance_id"
    t.string   "data_hash"
    t.string   "parent_id"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
    t.string   "package_id"
  end

  create_table "dvcs_configs", :force => true do |t|
    t.string   "name"
    t.string   "path"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "identifier"
    t.string   "data_hash"
  end

  create_table "issue_types", :force => true do |t|
    t.string   "name"
    t.text     "desc"
    t.string   "state"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "issues", :force => true do |t|
    t.string   "identifier"
    t.string   "project_id"
    t.string   "name"
    t.text     "desc"
    t.string   "code"
    t.string   "state"
    t.integer  "issue_type_id"
    t.string   "schedule_id"
    t.string   "created_by"
    t.string   "variance_parent_id"
    t.string   "variance_id"
    t.string   "data_hash"
    t.string   "parent_id"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
  end

  create_table "nodes", :force => true do |t|
    t.string   "identifier"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
    t.string   "state"
    t.string   "rights"
    t.string   "submitted_by"
  end

  create_table "packages", :force => true do |t|
    t.string   "identifier"
    t.string   "name"
    t.string   "data_hash"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "project_packages", :force => true do |t|
    t.string   "identifier"
    t.string   "project_id"
    t.string   "package_id"
    t.string   "data_hash"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "projects", :force => true do |t|
    t.string   "identifier"
    t.string   "name"
    t.text     "desc"
    t.text     "state"
    t.string   "created_by"
    t.string   "data_hash"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.string   "code"
    t.string   "category_tags"
  end

  create_table "schedules", :force => true do |t|
    t.string   "identifier"
    t.string   "schedulable_type"
    t.string   "schedulable_id"
    t.string   "name"
    t.text     "desc"
    t.string   "state"
    t.string   "data_hash"
    t.string   "created_by"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  create_table "sync_histories", :force => true do |t|
    t.string   "node_id"
    t.string   "sync_session_id"
    t.text     "sync_data"
    t.integer  "status"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
    t.string   "host"
  end

  create_table "sync_logs", :force => true do |t|
    t.string   "node_id"
    t.string   "user_id"
    t.integer  "last_change_log_id"
    t.string   "last_sync_from"
    t.integer  "direction"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
  end

  create_table "sync_merges", :force => true do |t|
    t.integer  "sync_history_id"
    t.string   "distributable_type"
    t.string   "distributable_id"
    t.text     "changeset"
    t.integer  "status"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
  end

  create_table "user_rights", :force => true do |t|
    t.integer  "user_id"
    t.string   "domain"
    t.string   "right"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "cert"
    t.string   "validation_token"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
    t.string   "state"
    t.string   "rights"
    t.string   "groups"
  end

  create_table "variances", :force => true do |t|
    t.string   "identifier"
    t.string   "project_id"
    t.string   "name"
    t.text     "desc"
    t.string   "state"
    t.string   "created_by"
    t.string   "data_hash"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "version_control_branches", :force => true do |t|
    t.string   "identifier"
    t.string   "data_hash"
    t.string   "project_status"
    t.string   "vcs_branch"
    t.string   "version_control_id"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
  end

  create_table "version_controls", :force => true do |t|
    t.string   "name"
    t.string   "versionable_type"
    t.string   "versionable_id"
    t.string   "upstream_vcs_class"
    t.string   "upstream_vcs_path"
    t.string   "upstream_vcs_branch"
    t.string   "vcs_class"
    t.string   "vcs_path"
    t.string   "vcs_branch"
    t.string   "created_by"
    t.string   "updated_by"
    t.string   "state"
    t.integer  "pushable_repo",       :default => 0
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
    t.string   "identifier"
    t.string   "data_hash"
    t.text     "notes"
  end

end
