require 'rails_helper'
require_relative '../../lib/job_tracker/cli'

RSpec.describe JobTracker::CLI do
  let(:cli) { described_class.new }

  describe '#list' do
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
  end

  describe '#show' do
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
  end

  describe '#update' do
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
