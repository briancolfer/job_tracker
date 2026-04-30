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
      cli.options = { status: [ 'applied' ] }
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

    it 'filters by --source' do
      create(:job_application, company: 'IndeedCo', source: 'Indeed')
      create(:job_application, company: 'LinkedInCo', source: 'LinkedIn')
      cli.options = { source: 'Indeed' }
      expect { cli.list }.to output(/IndeedCo/).to_stdout
      expect { cli.list }.not_to output(/LinkedInCo/).to_stdout
    end

    it 'filters by --arrangement remote' do
      create(:job_application, company: 'RemoteCo', days_in_office: 0)
      create(:job_application, company: 'OnsiteCo', days_in_office: 5)
      cli.options = { arrangement: 'remote' }
      expect { cli.list }.to output(/RemoteCo/).to_stdout
      expect { cli.list }.not_to output(/OnsiteCo/).to_stdout
    end

    it 'filters by --arrangement onsite' do
      create(:job_application, company: 'OnsiteCo', days_in_office: 5)
      create(:job_application, company: 'RemoteCo', days_in_office: 0)
      cli.options = { arrangement: 'onsite' }
      expect { cli.list }.to output(/OnsiteCo/).to_stdout
      expect { cli.list }.not_to output(/RemoteCo/).to_stdout
    end

    it 'filters by --arrangement hybrid (matches days 1-4)' do
      create(:job_application, company: 'HybridCo', days_in_office: 3)
      create(:job_application, company: 'RemoteCo', days_in_office: 0)
      cli.options = { arrangement: 'hybrid' }
      expect { cli.list }.to output(/HybridCo/).to_stdout
      expect { cli.list }.not_to output(/RemoteCo/).to_stdout
    end

    it 'filters by --arrangement with a raw integer' do
      create(:job_application, company: 'ThreeDayCo', days_in_office: 3)
      create(:job_application, company: 'FourDayCo', days_in_office: 4)
      cli.options = { arrangement: '3' }
      expect { cli.list }.to output(/ThreeDayCo/).to_stdout
      expect { cli.list }.not_to output(/FourDayCo/).to_stdout
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

    it 'shows Location line without (remote) annotation' do
      job = create(:job_application, location: 'Austin, TX', days_in_office: 0)
      expect { cli.show(job.id) }.to output(/Location:.*Austin, TX/).to_stdout
      expect { cli.show(job.id) }.not_to output(/\(remote\)/).to_stdout
    end

    it 'shows Arrangement: Remote when days_in_office is 0' do
      job = create(:job_application, days_in_office: 0)
      expect { cli.show(job.id) }.to output(/Arrangement:.*Remote/).to_stdout
    end

    it 'shows Arrangement: Hybrid (N days/week) when days_in_office is 1-4' do
      job = create(:job_application, days_in_office: 3)
      expect { cli.show(job.id) }.to output(/Arrangement:.*Hybrid \(3 days\/week\)/).to_stdout
    end

    it 'shows Arrangement: On-site (5 days/week) when days_in_office is 5' do
      job = create(:job_application, days_in_office: 5)
      expect { cli.show(job.id) }.to output(/Arrangement:.*On-site \(5 days\/week\)/).to_stdout
    end

    it 'shows Arrangement: Unknown when days_in_office is nil' do
      job = create(:job_application, days_in_office: nil)
      expect { cli.show(job.id) }.to output(/Arrangement:.*Unknown/).to_stdout
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

    it 'accepts --remote flag and sets days_in_office to 0' do
      cli.options = { company: 'NewCo', remote: true }
      cli.add
      expect(JobApplication.last.days_in_office).to eq(0)
    end

    it 'accepts --onsite flag and sets days_in_office to 5' do
      cli.options = { company: 'NewCo', onsite: true }
      cli.add
      expect(JobApplication.last.days_in_office).to eq(5)
    end

    it 'accepts --hybrid N flag and sets days_in_office to N' do
      cli.options = { company: 'NewCo', hybrid: 3 }
      cli.add
      expect(JobApplication.last.days_in_office).to eq(3)
    end

    it 'treats --hybrid 0 silently as remote (days_in_office: 0)' do
      cli.options = { company: 'NewCo', hybrid: 0 }
      cli.add
      expect(JobApplication.last.days_in_office).to eq(0)
    end

    it 'treats --hybrid 5 silently as onsite (days_in_office: 5)' do
      cli.options = { company: 'NewCo', hybrid: 5 }
      cli.add
      expect(JobApplication.last.days_in_office).to eq(5)
    end

    it 'errors when both --remote and --onsite are given' do
      cli.options = { company: 'NewCo', remote: true, onsite: true }
      expect { cli.add }.to output(/mutually exclusive/i).to_stdout
    end

    it 'does not create a record when arrangement flags conflict' do
      cli.options = { company: 'NewCo', remote: true, onsite: true }
      expect { cli.add }.not_to change(JobApplication, :count)
    end

    it 'errors when both --remote and --hybrid are given' do
      cli.options = { company: 'NewCo', remote: true, hybrid: 3 }
      expect { cli.add }.to output(/mutually exclusive/i).to_stdout
    end

    it 'errors when both --onsite and --hybrid are given' do
      cli.options = { company: 'NewCo', onsite: true, hybrid: 2 }
      expect { cli.add }.to output(/mutually exclusive/i).to_stdout
    end

    it 'leaves days_in_office nil when no arrangement flag is given' do
      cli.options = { company: 'NewCo' }
      cli.add
      expect(JobApplication.last.days_in_office).to be_nil
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

    it 'updates source of an existing application' do
      job = create(:job_application, source: 'LinkedIn')
      cli.options = { source: 'Indeed' }
      cli.update(job.id)
      expect(job.reload.source).to eq('Indeed')
    end

    it 'accepts --remote and sets days_in_office to 0' do
      job = create(:job_application, days_in_office: 3)
      cli.options = { remote: true }
      cli.update(job.id)
      expect(job.reload.days_in_office).to eq(0)
    end

    it 'accepts --onsite and sets days_in_office to 5' do
      job = create(:job_application, days_in_office: 3)
      cli.options = { onsite: true }
      cli.update(job.id)
      expect(job.reload.days_in_office).to eq(5)
    end

    it 'accepts --hybrid N and sets days_in_office to N' do
      job = create(:job_application, days_in_office: nil)
      cli.options = { hybrid: 2 }
      cli.update(job.id)
      expect(job.reload.days_in_office).to eq(2)
    end

    it 'errors when multiple arrangement flags are given on update' do
      job = create(:job_application)
      cli.options = { remote: true, onsite: true }
      expect { cli.update(job.id) }.to output(/mutually exclusive/i).to_stdout
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

    it 'exports days_in_office header instead of remote' do
      cli.options = { output: output_path }
      cli.export
      content = File.read(output_path)
      expect(content).to include('days_in_office')
      expect(content).not_to include('remote')
    end

    it 'exports the integer value of days_in_office' do
      create(:job_application, company: 'RemoteCo', days_in_office: 0)
      create(:job_application, company: 'HybridCo', days_in_office: 3)
      create(:job_application, company: 'UnknownCo', days_in_office: nil)
      cli.options = { output: output_path }
      cli.export
      rows = CSV.read(output_path, headers: true)
      expect(rows.find { |r| r['company'] == 'RemoteCo' }['days_in_office']).to eq('0')
      expect(rows.find { |r| r['company'] == 'HybridCo' }['days_in_office']).to eq('3')
      expect(rows.find { |r| r['company'] == 'UnknownCo' }['days_in_office']).to be_nil
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
