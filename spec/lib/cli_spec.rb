require 'rails_helper'
require_relative '../../lib/job_tracker/cli'

RSpec.describe JobTracker::CLI do
  let(:cli) { described_class.new }

  describe '#list' do
    it 'shows help with --help' do
      cli.options = { help: true }
      expect { cli.list }.to output(/Usage:/i).to_stdout
    end

    it 'outputs a table of job applications' do
      create(:job_application, company: 'Acme Corp', status: :applied)
      expect { cli.list }.to output(/Acme Corp/).to_stdout
    end

    it 'shows status in the output' do
      create(:job_application, company: 'Beta Inc', status: :phone_screen)
      expect { cli.list }.to output(/phone_screen/).to_stdout
    end

    it 'displays a message when no applications exist' do
      expect { cli.list }.to output(/No job applications found/).to_stdout
    end

    it 'filters by a single status' do
      create(:job_application, company: 'AppliedCo', status: :applied)
      create(:job_application, company: 'RejectedCo', status: :rejected)
      cli.options = { status: ['applied'] }
      expect { cli.list }.to output(/AppliedCo/).to_stdout
      expect { cli.list }.not_to output(/RejectedCo/).to_stdout
    end

    it 'filters by multiple statuses' do
      create(:job_application, company: 'AppliedCo', status: :applied)
      create(:job_application, company: 'PhoneCo', status: :phone_screen)
      create(:job_application, company: 'RejectedCo', status: :rejected)
      cli.options = { status: %w[applied phone_screen] }
      expect { cli.list }.to output(/AppliedCo/).to_stdout
      expect { cli.list }.to output(/PhoneCo/).to_stdout
      expect { cli.list }.not_to output(/RejectedCo/).to_stdout
    end

    it 'filters by --after date (greater than or equal)' do
      create(:job_application, company: 'OldCo', apply_date: '2026-01-01')
      create(:job_application, company: 'NewCo', apply_date: '2026-04-01')
      cli.options = { after: '2026-02-01' }
      expect { cli.list }.to output(/NewCo/).to_stdout
      expect { cli.list }.not_to output(/OldCo/).to_stdout
    end

    it 'filters by --before date (less than or equal)' do
      create(:job_application, company: 'OldCo', apply_date: '2026-01-01')
      create(:job_application, company: 'NewCo', apply_date: '2026-04-01')
      cli.options = { before: '2026-02-01' }
      expect { cli.list }.to output(/OldCo/).to_stdout
      expect { cli.list }.not_to output(/NewCo/).to_stdout
    end

    it 'filters by a date range using --after and --before together' do
      create(:job_application, company: 'TooOldCo', apply_date: '2026-01-01')
      create(:job_application, company: 'InRangeCo', apply_date: '2026-03-01')
      create(:job_application, company: 'TooNewCo', apply_date: '2026-05-01')
      cli.options = { after: '2026-02-01', before: '2026-04-01' }
      expect { cli.list }.to output(/InRangeCo/).to_stdout
      expect { cli.list }.not_to output(/TooOldCo/).to_stdout
      expect { cli.list }.not_to output(/TooNewCo/).to_stdout
    end

    it 'shows an error for an invalid --after date' do
      cli.options = { after: 'not-a-date' }
      expect { cli.list }.to output(/invalid date/i).to_stdout
    end

    it 'shows an error for an invalid --before date' do
      cli.options = { before: 'not-a-date' }
      expect { cli.list }.to output(/invalid date/i).to_stdout
    end
  end

  describe '#show' do
    it 'shows help with --help' do
      cli.options = { help: true }
      expect { cli.show(nil) }.to output(/Usage:/i).to_stdout
    end

    it 'displays job application details' do
      job = create(:job_application, company: 'Gamma LLC', role_title: 'SRE')
      expect { cli.show(job.id) }.to output(/Gamma LLC/).to_stdout
      expect { cli.show(job.id) }.to output(/SRE/).to_stdout
    end

    it 'shows an error for unknown id' do
      expect { cli.show(99999) }.to output(/not found/i).to_stdout
    end
  end

  describe '#add' do
    it 'shows help with --help' do
      cli.options = { help: true }
      expect { cli.add }.to output(/Usage:/i).to_stdout
    end

    it 'shows an error when company is not provided' do
      cli.options = {}
      expect { cli.add }.to output(/company is required/i).to_stdout
    end

    it 'creates a new job application' do
      expect {
        cli.options = { company: 'NewCo', apply_date: '2026-03-24', status: 'applied' }
        cli.add
      }.to change(JobApplication, :count).by(1)
    end

    it 'outputs confirmation after creation' do
      cli.options = { company: 'NewCo', apply_date: '2026-03-24', status: 'applied' }
      expect { cli.add }.to output(/created/i).to_stdout
    end

    it 'defaults apply_date to today when not provided' do
      cli.options = { company: 'NewCo', status: 'applied' }
      cli.add
      expect(JobApplication.last.apply_date).to eq(Date.today)
    end

    it 'accepts role_title option' do
      cli.options = { company: 'NewCo', role: 'Senior DevOps' }
      cli.add
      expect(JobApplication.last.role_title).to eq('Senior DevOps')
    end

    it 'accepts job_type option' do
      cli.options = { company: 'NewCo', job_type: 'Full-time' }
      cli.add
      expect(JobApplication.last.job_type).to eq('Full-time')
    end

    it 'accepts location option' do
      cli.options = { company: 'NewCo', location: 'San Francisco, CA' }
      cli.add
      expect(JobApplication.last.location).to eq('San Francisco, CA')
    end

    it 'accepts remote flag' do
      cli.options = { company: 'NewCo', remote: true }
      cli.add
      expect(JobApplication.last.remote).to be true
    end

    it 'accepts source option' do
      cli.options = { company: 'NewCo', source: 'LinkedIn' }
      cli.add
      expect(JobApplication.last.source).to eq('LinkedIn')
    end

    it 'accepts url option' do
      cli.options = { company: 'NewCo', url: 'https://example.com/job/123' }
      cli.add
      expect(JobApplication.last.job_posting_url).to eq('https://example.com/job/123')
    end

    it 'accepts notes option' do
      cli.options = { company: 'NewCo', notes: 'Great company culture' }
      cli.add
      expect(JobApplication.last.notes).to eq('Great company culture')
    end

    it 'accepts a non-default status option' do
      cli.options = { company: 'NewCo', status: 'phone_screen' }
      cli.add
      expect(JobApplication.last.status).to eq('phone_screen')
    end

    it 'defaults status to applied when not provided' do
      cli.options = { company: 'NewCo' }
      cli.add
      expect(JobApplication.last.status).to eq('applied')
    end

    it 'shows an error for an invalid status' do
      cli.options = { company: 'NewCo', status: 'interviewed' }
      expect { cli.add }.to output(/invalid status/i).to_stdout
    end

    it 'does not create a record when status is invalid' do
      cli.options = { company: 'NewCo', status: 'interviewed' }
      expect { cli.add }.not_to change(JobApplication, :count)
    end
  end

  describe '#statuses' do
    it 'shows help with --help' do
      cli.options = { help: true }
      expect { cli.statuses }.to output(/Usage:/i).to_stdout
    end

    it 'lists all valid statuses' do
      expect { cli.statuses }.to output(/cold_call.*applied.*phone_screen.*technical_screen.*onsite.*offer_received.*accepted.*rejected.*withdrawn.*ghosted/m).to_stdout
    end
  end

  describe '#status' do
    it 'shows help with --help' do
      cli.options = { help: true }
      expect { cli.status(nil, nil) }.to output(/Usage:/i).to_stdout
    end

    it 'updates the status of an existing application' do
      job = create(:job_application, status: :applied)
      cli.status(job.id, 'phone_screen')
      expect(job.reload.status).to eq('phone_screen')
    end

    it 'prints confirmation after updating status' do
      job = create(:job_application, status: :applied)
      expect { cli.status(job.id, 'rejected') }.to output(/updated/i).to_stdout
    end

    it 'shows an error for an unknown id' do
      expect { cli.status(99999, 'applied') }.to output(/not found/i).to_stdout
    end

    it 'shows an error for an invalid status' do
      job = create(:job_application, status: :applied)
      expect { cli.status(job.id, 'interviewed') }.to output(/invalid status/i).to_stdout
    end
  end

  describe '#update' do
    it 'shows help with --help' do
      cli.options = { help: true }
      expect { cli.update(nil) }.to output(/Usage:/i).to_stdout
    end

    it 'updates the status of an existing application' do
      job = create(:job_application, status: :applied)
      cli.options = { status: 'phone_screen' }
      cli.update(job.id)
      expect(job.reload.status).to eq('phone_screen')
    end

    it 'outputs confirmation after update' do
      job = create(:job_application, status: :applied)
      cli.options = { status: 'rejected' }
      expect { cli.update(job.id) }.to output(/updated/i).to_stdout
    end
  end

  describe '#export' do
    it 'shows help with --help' do
      cli.options = { help: true }
      expect { cli.export }.to output(/Usage:/i).to_stdout
    end

    let(:output_path) { Rails.root.join('tmp', 'test_export.csv').to_s }

    after { File.delete(output_path) if File.exist?(output_path) }

    it 'writes a CSV file to the specified path' do
      create(:job_application, company: 'ExportCo', status: :applied)
      cli.options = { output: output_path }
      cli.export
      expect(File.exist?(output_path)).to be true
    end

    it 'includes a header row' do
      cli.options = { output: output_path }
      cli.export
      content = File.read(output_path)
      expect(content).to match(/company/i)
      expect(content).to match(/status/i)
      expect(content).to match(/apply_date/i)
    end

    it 'includes all job applications' do
      create(:job_application, company: 'AlphaCorp', status: :applied)
      create(:job_application, company: 'BetaCorp', status: :rejected)
      cli.options = { output: output_path }
      cli.export
      content = File.read(output_path)
      expect(content).to include('AlphaCorp')
      expect(content).to include('BetaCorp')
    end

    it 'prints confirmation with row count' do
      create(:job_application)
      cli.options = { output: output_path }
      expect { cli.export }.to output(/exported/i).to_stdout
    end

    it 'defaults output path to job_applications_<date>.csv' do
      cli.options = {}
      expect { cli.export }.to output(/Exported/).to_stdout
    ensure
      Dir.glob(Rails.root.join('tmp', 'job_applications_*.csv')).each { |f| File.delete(f) }
    end
  end

  describe '#reminders' do
    it 'shows help with --help' do
      cli.options = { help: true }
      expect { cli.reminders }.to output(/Usage:/i).to_stdout
    end

    it 'shows overdue follow-ups' do
      job = create(:job_application, company: 'OverdueInc')
      create(:follow_up, job_application: job, due_date: 3.days.ago, completed: false,
             description: 'Check in with recruiter')
      expect { cli.reminders }.to output(/OverdueInc/).to_stdout
      expect { cli.reminders }.to output(/Check in with recruiter/).to_stdout
    end

    it 'shows a message when no follow-ups are overdue' do
      expect { cli.reminders }.to output(/No overdue follow-ups/).to_stdout
    end
  end
end
