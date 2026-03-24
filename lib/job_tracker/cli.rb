require 'thor'

module JobTracker
  class CLI < Thor
    STATUSES = %w[cold_call applied phone_screen technical_screen onsite offer_received accepted rejected withdrawn ghosted].freeze

    desc 'list', 'List all job applications'
    method_option :status, aliases: '-s', desc: 'Filter by status'
    method_option :active, aliases: '-a', type: :boolean, desc: 'Show only active applications'
    def list
      applications = JobApplication.order(apply_date: :desc)
      applications = applications.where(status: options[:status]) if options[:status]
      applications = applications.active if options[:active]

      if applications.empty?
        puts 'No job applications found.'
        return
      end

      puts format_row('ID', 'Company', 'Role', 'Status', 'Date')
      puts '-' * 80
      applications.each do |job|
        puts format_row(job.id, job.company, job.role_title.to_s, job.status, job.apply_date)
      end
    end

    desc 'show ID', 'Show details for a job application'
    def show(id)
      job = JobApplication.find_by(id: id)
      unless job
        puts "Job application ##{id} not found."
        return
      end

      puts "\n=== #{job.company} ==="
      puts "  Role:        #{job.role_title}"
      puts "  Type:        #{job.job_type}"
      puts "  Location:    #{job.location}#{job.remote? ? ' (remote)' : ''}"
      puts "  Source:      #{job.source}"
      puts "  Status:      #{job.status}"
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
          overdue = fu.due_date < Date.today ? ' [OVERDUE]' : ''
          puts "    - #{fu.due_date}#{overdue}: #{fu.description}"
        end
      end
    end

    desc 'add', 'Add a new job application'
    method_option :company, aliases: '-c', required: true, desc: 'Company name'
    method_option :apply_date, aliases: '-d', default: Date.today.to_s, desc: 'Application date (YYYY-MM-DD)'
    method_option :role, aliases: '-r', desc: 'Role title'
    method_option :job_type, aliases: '-t', desc: 'Job type (e.g. DevOps, SRE)'
    method_option :location, aliases: '-l', desc: 'Location'
    method_option :source, aliases: '-S', desc: 'Source (e.g. LinkedIn, Indeed)'
    method_option :status, aliases: '-s', default: 'applied', desc: "Status (#{STATUSES.join(', ')})"
    method_option :url, aliases: '-u', desc: 'Job posting URL'
    method_option :notes, aliases: '-n', desc: 'Notes'
    def add
      job = JobApplication.new(
        company: options[:company],
        apply_date: options[:apply_date],
        role_title: options[:role],
        job_type: options[:job_type],
        location: options[:location],
        source: options[:source],
        status: options[:status],
        job_posting_url: options[:url],
        notes: options[:notes]
      )

      if job.save
        puts "Created job application ##{job.id}: #{job.company} (#{job.status})"
      else
        puts "Error: #{job.errors.full_messages.join(', ')}"
      end
    end

    desc 'update ID', 'Update a job application'
    method_option :status, aliases: '-s', desc: "New status (#{STATUSES.join(', ')})"
    method_option :role, aliases: '-r', desc: 'Role title'
    method_option :notes, aliases: '-n', desc: 'Notes'
    method_option :url, aliases: '-u', desc: 'Job posting URL'
    def update(id)
      job = JobApplication.find_by(id: id)
      unless job
        puts "Job application ##{id} not found."
        return
      end

      attrs = {}
      attrs[:status] = options[:status] if options[:status]
      attrs[:role_title] = options[:role] if options[:role]
      attrs[:notes] = options[:notes] if options[:notes]
      attrs[:job_posting_url] = options[:url] if options[:url]

      if job.update(attrs)
        puts "Updated job application ##{job.id}: #{job.company} (#{job.status})"
      else
        puts "Error: #{job.errors.full_messages.join(', ')}"
      end
    end

    desc 'reminders', 'Show overdue and upcoming follow-ups'
    def reminders
      overdue = FollowUp.overdue.includes(:job_application).order(:due_date)
      due_today = FollowUp.due_today.includes(:job_application).order(:due_date)

      if overdue.empty? && due_today.empty?
        puts 'No overdue follow-ups.'
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

    def format_row(*cols)
      format('%-6s %-25s %-20s %-18s %-12s', *cols.map(&:to_s))
    end
  end
end
