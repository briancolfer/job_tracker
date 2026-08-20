require "thor"
require "csv"
require "chronic"
require_relative "date_parser"
require_relative "status_catalog"

module JobTracker
  class CLI < Thor
    desc "list", "List all job applications"

    method_option :help, aliases: "-h", type: :boolean, desc: "Show help for this command"
    method_option :status, aliases: "-s", type: :array, desc: "Filter by one or more statuses (e.g. --status applied phone_screen)"
    method_option :active, aliases: "-a", type: :boolean, desc: "Show only active applications"
    method_option :after, aliases: "-A", type: :string, desc: "Show applications on or after this date (YYYY-MM-DD)"
    method_option :before, aliases: "-B", type: :string, desc: "Show applications on or before this date (YYYY-MM-DD)"
    method_option :source, aliases: "-S", type: :string, desc: "Filter by source (e.g. Indeed, LinkedIn)"
    method_option :arrangement, type: :string, desc: "Filter by work arrangement (remote, hybrid, onsite, or integer 0-5)"

    def list
      return help("list") if options[:help]

      after_date = parse_date_option(:after)
      before_date = parse_date_option(:before)
      return if after_date == :invalid || before_date == :invalid

      applications = JobApplication.order(apply_date: :desc)
      applications = applications.where(status: options[:status]) if options[:status]
      applications = applications.active if options[:active]
      applications = applications.applied_after(after_date) if after_date
      applications = applications.applied_before(before_date) if before_date
      applications = applications.where(source: options[:source]) if options[:source]
      if options[:arrangement]
        days = arrangement_to_days(options[:arrangement])
        applications = applications.where(days_in_office: days)
      end

      if applications.empty?
        puts "No job applications found."
        return
      end

      puts format_row("ID", "Company", "Role", "Status", "Date")
      puts "-" * 80
      applications.each do |job|
        puts format_row(job.id, job.company, job.role_title.to_s, status_display(job), job.apply_date)
      end
    end

    desc "show ID", "Show details for a job application"
    method_option :help, aliases: "-h", type: :boolean, desc: "Show help for this command"

    def show(id = nil)
      return help("show") if options[:help]

      job = JobApplication.find_by(id: id)
      unless job
        puts "Job application ##{id} not found."
        return
      end

      puts "\n=== #{job.company} ==="
      puts "  Role:        #{job.role_title}"
      puts "  Type:        #{job.job_type}"
      puts "  Location:    #{job.location}"
      puts "  Arrangement: #{job.arrangement_label}"
      puts "  Source:      #{job.source}"
      puts "  Status:      #{status_display(job)}"
      puts "  Applied:     #{job.apply_date}"
      puts "  URL:         #{job.job_posting_url}"
      puts "  Notes:       #{job.notes}" if job.notes.present?

      if job.interview_stages.any?
        puts "\n  Interview Stages:"
        job.interview_stages.each do |stage|
          puts "    - #{stage.stage_type} | #{stage.outcome} | #{stage.scheduled_at&.strftime('%Y-%m-%d')}"
          puts "      #{stage.notes}" if stage.notes.present?
        end
      end

      if job.contacts.any?
        puts "\n  Contacts:"
        job.contacts.each do |contact|
          puts "    - #{contact.name} (#{contact.role}) #{contact.email}"
        end
      end

      if job.follow_ups.pending.any?
        puts "\n  Pending Follow-ups:"
        job.follow_ups.pending.order(:due_date).each do |fu|
          overdue = fu.due_date < Date.today ? " [OVERDUE]" : ""
          puts "    - #{fu.due_date}#{overdue}: #{fu.description}"
        end
      end
    end

    desc "add", "Add a new job application"
    method_option :help, aliases: "-h", type: :boolean, desc: "Show help for this command"
    method_option :company, aliases: "-c", desc: "Company name"
    method_option :apply_date, aliases: "-d", default: Date.today.to_s, desc: "Application date (YYYY-MM-DD)"
    method_option :role, aliases: "-r", desc: "Role title"
    method_option :job_type, aliases: "-t", desc: "Job type (e.g. DevOps, SRE)"
    method_option :location, aliases: "-l", desc: "Location"
    method_option :remote, type: :boolean, desc: "Remote position (sets days_in_office: 0)"
    method_option :onsite, type: :boolean, desc: "On-site position (sets days_in_office: 5)"
    method_option :hybrid, type: :numeric, desc: "Hybrid: days in office per week 0-5 (sets days_in_office: N)"
    method_option :source, aliases: "-S", desc: "Source (e.g. LinkedIn, Indeed)"
    method_option :status, aliases: "-s", default: "applied", desc: "Status code (see `bin/jt statuses`)"
    method_option :url, aliases: "-u", desc: "Job posting URL"
    method_option :notes, aliases: "-n", desc: "Notes"

    def add
      return help("add") if options[:help]

      unless options[:company].present?
        puts "Error: company is required (-c COMPANY)"
        return
      end

      status = options[:status] || "applied"
      unless status_codes.include?(status)
        puts "Invalid status '#{status}'. Valid statuses: #{status_codes.join(', ')}"
        return
      end

      days = resolve_days_in_office
      return if days == :conflict

      apply_date = parse_date_option(:apply_date) || Date.today
      return if apply_date == :invalid

      job = JobApplication.new(
        company: options[:company],
        apply_date: apply_date,
        role_title: options[:role],
        job_type: options[:job_type],
        location: options[:location],
        days_in_office: days,
        source: options[:source],
        status: status,
        job_posting_url: options[:url],
        notes: options[:notes]
      )

      if job.save
        puts "Created job application ##{job.id}: #{job.company} (#{job.status})"
      else
        puts "Error: #{job.errors.full_messages.join(', ')}"
      end
    end

    desc "statuses", "List all valid job application statuses"
    method_option :help, aliases: "-h", type: :boolean, desc: "Show help for this command"

    def statuses
      return help("statuses") if options[:help]

      puts "Valid statuses:"
      JobTracker::StatusCatalog.definitions.each do |code, attributes|
        terminal = attributes["terminal"] ? " [terminal]" : ""
        puts "  #{code.ljust(20)} #{attributes.fetch('label')}#{terminal}"
      end
    end

    desc "status ID NEW_STATUS", "Update the status code of a job application"
    method_option :help, aliases: "-h", type: :boolean, desc: "Show help for this command"

    def status(id = nil, new_status = nil)
      return help("status") if options[:help]

      job = JobApplication.find_by(id: id)
      unless job
        puts "Job application ##{id} not found."
        return
      end

      unless status_codes.include?(new_status)
        puts "Invalid status '#{new_status}'. Valid statuses: #{status_codes.join(', ')}"
        return
      end

      if job.update(status: new_status)
        puts "Updated job application ##{job.id}: #{job.company} (#{job.status})"
      else
        puts "Error: #{job.errors.full_messages.join(', ')}"
      end
    end

    desc "update ID", "Update a job application"
    method_option :help, aliases: "-h", type: :boolean, desc: "Show help for this command"
    method_option :status, aliases: "-s", desc: "New status code (see `bin/jt statuses`)"
    method_option :role, aliases: "-r", desc: "Role title"
    method_option :notes, aliases: "-n", desc: "Notes"
    method_option :url, aliases: "-u", desc: "Job posting URL"
    method_option :source, aliases: "-S", desc: "Source (e.g. LinkedIn, Indeed)"
    method_option :remote, type: :boolean, desc: "Remote position (sets days_in_office: 0)"
    method_option :onsite, type: :boolean, desc: "On-site position (sets days_in_office: 5)"
    method_option :hybrid, type: :numeric, desc: "Hybrid: days in office per week 0-5 (sets days_in_office: N)"

    def update(id = nil)
      return help("update") if options[:help]

      job = JobApplication.find_by(id: id)
      unless job
        puts "Job application ##{id} not found."
        return
      end

      days = resolve_days_in_office
      return if days == :conflict

      if options[:status] && !status_codes.include?(options[:status])
        puts "Invalid status '#{options[:status]}'. Valid statuses: #{status_codes.join(', ')}"
        return
      end

      attrs = {}
      attrs[:status] = options[:status] if options[:status]
      attrs[:role_title] = options[:role] if options[:role]
      attrs[:notes] = options[:notes] if options[:notes]
      attrs[:job_posting_url] = options[:url] if options[:url]
      attrs[:source] = options[:source] if options[:source]
      attrs[:days_in_office] = days unless days.nil?

      if job.update(attrs)
        puts "Updated job application ##{job.id}: #{job.company} (#{job.status})"
      else
        puts "Error: #{job.errors.full_messages.join(', ')}"
      end
    end

    desc "status-add CODE", "Add a new enum status code"
    method_option :help, aliases: "-h", type: :boolean, desc: "Show help for this command"
    method_option :label, type: :string, desc: "Display label"
    method_option :terminal, type: :boolean, default: false, desc: "Mark as a terminal status"

    def status_add(code = nil)
      return help("status-add") if options[:help]

      attributes = JobTracker::StatusCatalog.add(
        code,
        label: options[:label],
        terminal: options[:terminal]
      )
      puts "Added status #{code}: #{attributes.fetch('label')} (value #{attributes.fetch('value')})."
      puts "The new enum is available to newly started CLI and web processes."
    rescue JobTracker::StatusCatalog::ValidationError => e
      puts "Error: #{e.message}"
    end

    desc "status-update CODE", "Update an enum status code or display label"
    method_option :help, aliases: "-h", type: :boolean, desc: "Show help for this command"
    method_option :new_code, type: :string, desc: "Replacement enum code"
    method_option :label, type: :string, desc: "Replacement display label"
    method_option :terminal, type: :boolean, desc: "Mark terminal or use --no-terminal to mark active"

    def status_update(code = nil)
      return help("status-update") if options[:help]

      terminal = options.key?(:terminal) ? options[:terminal] : nil
      attributes = JobTracker::StatusCatalog.update(
        code,
        new_code: options[:new_code],
        label: options[:label],
        terminal: terminal
      )
      updated_code = options[:new_code].presence || code
      puts "Updated status #{updated_code}: #{attributes.fetch('label')} (value #{attributes.fetch('value')})."
      puts "The updated enum is available to newly started CLI and web processes."
    rescue JobTracker::StatusCatalog::ValidationError => e
      puts "Error: #{e.message}"
    end

    desc "export", "Export all job applications to CSV"
    method_option :help, aliases: "-h", type: :boolean, desc: "Show help for this command"
    method_option :output, aliases: "-o", desc: "Output file path (default: tmp/job_applications_<date>.csv)"
    method_option :status, aliases: "-s", desc: "Filter by status"

    def export
      return help("export") if options[:help]

      default_path = Rails.root.join("tmp", "job_applications_#{Date.today}.csv").to_s
      path = options[:output] || default_path

      applications = JobApplication.order(apply_date: :desc)
      applications = applications.where(status: options[:status]) if options[:status]

      CSV.open(path, "w") do |csv|
        csv << %w[id company role_title job_type location days_in_office source status apply_date job_posting_url notes]
        applications.each do |job|
          csv << [
            job.id,
            job.company,
            job.role_title,
            job.job_type,
            job.location,
            job.days_in_office,
            job.source,
            job.status,
            job.apply_date,
            job.job_posting_url,
            job.notes
          ]
        end
      end

      puts "Exported #{applications.count} application(s) to #{path}"
    end

    desc "reminders", "Show overdue and upcoming follow-ups"
    method_option :help, aliases: "-h", type: :boolean, desc: "Show help for this command"

    def reminders
      return help("reminders") if options[:help]

      overdue = FollowUp.overdue.includes(:job_application).order(:due_date)
      due_today = FollowUp.due_today.includes(:job_application).order(:due_date)

      if overdue.empty? && due_today.empty?
        puts "No overdue follow-ups."
        return
      end

      unless overdue.empty?
        puts "\n[OVERDUE]"
        overdue.each do |fu|
          puts "  #{fu.due_date} | #{fu.job_application.company} | #{fu.description}"
        end
      end

      unless due_today.empty?
        puts "\n[DUE TODAY]"
        due_today.each do |fu|
          puts "  #{fu.due_date} | #{fu.job_application.company} | #{fu.description}"
        end
      end
    end

    private

    def status_codes
      JobTracker::StatusCatalog.codes
    end

    def status_display(job_application)
      "#{job_application.status_label} (#{job_application.status})"
    end

    def parse_date_option(key)
      return nil unless options[key]

      JobTracker::DateParser.parse(options[key])

    rescue ArgumentError
      puts "Error: invalid date for --#{key}: '#{options[key]}'"
      puts "Use YYYY-MM-DD or natural language like '1 week ago'."
      :invalid
    end

    def format_row(*cols)
      format("%-6s %-25s %-20s %-18s %-12s", *cols.map(&:to_s))
    end

    def resolve_days_in_office
      given = [
        (options[:remote] ? "--remote" : nil),
        (options[:onsite] ? "--onsite" : nil),
        (!options[:hybrid].nil? ? "--hybrid" : nil)
      ].compact

      if given.size > 1
        puts "Error: #{given.join(', ')} are mutually exclusive. Specify only one work arrangement."
        return :conflict
      end

      if options[:remote]
        0
      elsif options[:onsite]
        5
      elsif !options[:hybrid].nil?
        options[:hybrid].to_i
      end
      # returns nil when no flag given
    end

    def arrangement_to_days(value)
      case value.to_s.downcase
      when "remote" then [ 0 ]
      when "onsite" then [ 5 ]
      when "hybrid" then [ 1, 2, 3, 4 ]
      else [ value.to_i ]
      end
    end
  end
end
