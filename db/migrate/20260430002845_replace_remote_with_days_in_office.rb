class ReplaceRemoteWithDaysInOffice < ActiveRecord::Migration[8.1]
  def up
    add_column :job_applications, :days_in_office, :integer

    # Backfill: true -> 0 (remote), false -> 5 (on-site), nil -> nil (unknown)
    execute <<~SQL
      UPDATE job_applications
      SET days_in_office = CASE
        WHEN remote = 1 THEN 0
        WHEN remote = 0 THEN 5
        ELSE NULL
      END
    SQL

    remove_column :job_applications, :remote
  end

  def down
    add_column :job_applications, :remote, :boolean

    execute <<~SQL
      UPDATE job_applications
      SET remote = CASE
        WHEN days_in_office = 0 THEN 1
        WHEN days_in_office IS NOT NULL THEN 0
        ELSE NULL
      END
    SQL

    remove_column :job_applications, :days_in_office
  end
end
