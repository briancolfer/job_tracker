class CreateJobStatuses < ActiveRecord::Migration[8.1]
  def change
    create_table :job_statuses do |t|
      t.string :code, null: false
      t.integer :value, null: false
      t.string :label, null: false
      t.boolean :terminal, null: false, default: false
      t.boolean :default, null: false, default: false

      t.timestamps
    end

    add_index :job_statuses, :code, unique: true
    add_index :job_statuses, :value, unique: true
    add_index :job_statuses, :default, unique: true, where: "\"default\" = 1"
  end
end
