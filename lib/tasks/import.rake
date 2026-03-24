require 'csv'

namespace :import do
  desc 'Import job applications from CSV. Usage: rake import:csv[path/to/file.csv]'
  task :csv, [:file_path] => :environment do |_t, args|
    file_path = args[:file_path] || ENV['FILE']
    abort 'Usage: rake import:csv[path/to/file.csv]' unless file_path

    expanded = File.expand_path(file_path)
    abort "File not found: #{expanded}" unless File.exist?(expanded)

    # Map CSV status strings to enum values
    STATUS_MAP = {
      'applied'                    => :applied,
      'applied, rejected'          => :rejected,
      'applied, interviewing'      => :phone_screen,
      'recruiter submitted'        => :applied,
      'cold call'                  => :cold_call,
    }.freeze

    def normalize_status(raw)
      return :applied if raw.blank?
      STATUS_MAP[raw.downcase.strip] || :applied
    end

    imported = 0
    skipped  = 0

    CSV.foreach(expanded, headers: true) do |row|
      company = row['Job']&.strip
      next if company.blank?

      apply_date_raw = row['apply date']&.strip
      apply_date = begin
        Date.parse(apply_date_raw)
      rescue ArgumentError, TypeError
        Date.today
      end

      status = normalize_status(row['Status'])

      # Parse phone screen note (e.g. "Yes: good")
      phone_screen_note = row['Initial phone screen']&.strip
      had_phone_screen = phone_screen_note.present? && phone_screen_note.downcase.start_with?('yes')

      job = JobApplication.create!(
        company:        company,
        role_title:     row['job type']&.strip,
        job_type:       row['job type']&.strip,
        location:       row['location']&.strip,
        source:         row['source']&.strip,
        status:         status,
        apply_date:     apply_date,
        job_posting_url: row['link']&.strip,
        notes:          row['Notes']&.strip
      )

      if had_phone_screen
        job.interview_stages.create!(
          stage_type: :phone_screen,
          outcome:    :passed,
          notes:      phone_screen_note
        )
      end

      imported += 1
    rescue ActiveRecord::RecordInvalid => e
      puts "  Skipped row (#{company}): #{e.message}"
      skipped += 1
    end

    puts "\nImport complete: #{imported} imported, #{skipped} skipped."
  end
end
