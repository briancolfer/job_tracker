class CreateJobApplications < ActiveRecord::Migration[8.1]
  def change
    create_table :job_applications do |t|
      t.string :company
      t.string :role_title
      t.string :job_type
      t.string :location
      t.boolean :remote
      t.string :source
      t.integer :status
      t.date :apply_date
      t.string :job_posting_url
      t.text :notes

      t.timestamps
    end
  end
end
