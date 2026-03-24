class CreateFollowUps < ActiveRecord::Migration[8.1]
  def change
    create_table :follow_ups do |t|
      t.references :job_application, null: false, foreign_key: true
      t.date :due_date
      t.string :description
      t.boolean :completed

      t.timestamps
    end
  end
end
