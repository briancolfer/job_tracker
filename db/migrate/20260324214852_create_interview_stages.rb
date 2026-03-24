class CreateInterviewStages < ActiveRecord::Migration[8.1]
  def change
    create_table :interview_stages do |t|
      t.references :job_application, null: false, foreign_key: true
      t.integer :stage_type
      t.datetime :scheduled_at
      t.datetime :completed_at
      t.integer :outcome
      t.text :notes

      t.timestamps
    end
  end
end
