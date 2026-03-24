class CreateContacts < ActiveRecord::Migration[8.1]
  def change
    create_table :contacts do |t|
      t.references :job_application, null: false, foreign_key: true
      t.string :name
      t.integer :role
      t.string :email
      t.string :phone
      t.string :linkedin_url
      t.text :notes

      t.timestamps
    end
  end
end
