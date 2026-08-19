require 'rails_helper'

RSpec.describe JobApplication, type: :model do
  describe 'validations' do
    it 'is valid with a company and apply_date' do
      job = build(:job_application)
      expect(job).to be_valid
    end

    it 'is invalid without a company' do
      job = build(:job_application, company: nil)
      expect(job).not_to be_valid
      expect(job.errors[:company]).to include("can't be blank")
    end

    it 'is invalid without an apply_date' do
      job = build(:job_application, apply_date: nil)
      expect(job).not_to be_valid
      expect(job.errors[:apply_date]).to include("can't be blank")
    end
  end

  describe 'status enum' do
    it 'defaults to applied' do
      job = build(:job_application)
      expect(job.status).to eq('applied')
    end

    it 'supports all pipeline statuses' do
      %w[cold_call applied phone_screen technical_screen onsite offer_received accepted rejected withdrawn ghosted].each do |s|
        job = build(:job_application, status: s)
        expect(job).to be_valid
      end
    end

    it 'reports an invalid status as a validation error' do
      job = build(:job_application, status: 'not_a_status')

      expect(job).not_to be_valid
      expect(job.errors[:status]).to include('is not included in the list')
    end
  end

  describe 'associations' do
    it 'has many interview_stages' do
      association = described_class.reflect_on_association(:interview_stages)
      expect(association.macro).to eq(:has_many)
    end

    it 'has many contacts' do
      association = described_class.reflect_on_association(:contacts)
      expect(association.macro).to eq(:has_many)
    end

    it 'has many follow_ups' do
      association = described_class.reflect_on_association(:follow_ups)
      expect(association.macro).to eq(:has_many)
    end
  end

  describe 'days_in_office' do
    describe 'validation' do
      it 'is valid when nil (unknown arrangement)' do
        job = build(:job_application, days_in_office: nil)
        expect(job).to be_valid
      end

      (0..5).each do |n|
        it "is valid with days_in_office: #{n}" do
          job = build(:job_application, days_in_office: n)
          expect(job).to be_valid
        end
      end

      it 'is invalid when days_in_office is below 0' do
        job = build(:job_application, days_in_office: -1)
        expect(job).not_to be_valid
        expect(job.errors[:days_in_office]).to be_present
      end

      it 'is invalid when days_in_office is above 5' do
        job = build(:job_application, days_in_office: 6)
        expect(job).not_to be_valid
        expect(job.errors[:days_in_office]).to be_present
      end
    end

    describe '#remote?' do
      it 'returns true when days_in_office is 0' do
        expect(build(:job_application, days_in_office: 0).remote?).to be true
      end

      it 'returns false when days_in_office is not 0' do
        expect(build(:job_application, days_in_office: 3).remote?).to be false
      end

      it 'returns false when days_in_office is nil' do
        expect(build(:job_application, days_in_office: nil).remote?).to be false
      end
    end

    describe '#hybrid?' do
      it 'returns true when days_in_office is between 1 and 4' do
        (1..4).each do |n|
          expect(build(:job_application, days_in_office: n).hybrid?).to be true
        end
      end

      it 'returns false when days_in_office is 0' do
        expect(build(:job_application, days_in_office: 0).hybrid?).to be false
      end

      it 'returns false when days_in_office is 5' do
        expect(build(:job_application, days_in_office: 5).hybrid?).to be false
      end

      it 'returns false when days_in_office is nil' do
        expect(build(:job_application, days_in_office: nil).hybrid?).to be false
      end
    end

    describe '#onsite?' do
      it 'returns true when days_in_office is 5' do
        expect(build(:job_application, days_in_office: 5).onsite?).to be true
      end

      it 'returns false when days_in_office is not 5' do
        expect(build(:job_application, days_in_office: 3).onsite?).to be false
      end

      it 'returns false when days_in_office is nil' do
        expect(build(:job_application, days_in_office: nil).onsite?).to be false
      end
    end

    describe '#arrangement_label' do
      it 'returns "Remote" when days_in_office is 0' do
        expect(build(:job_application, days_in_office: 0).arrangement_label).to eq('Remote')
      end

      it 'returns "Hybrid (N days/week)" when days_in_office is 1-4' do
        (1..4).each do |n|
          expect(build(:job_application, days_in_office: n).arrangement_label).to eq("Hybrid (#{n} days/week)")
        end
      end

      it 'returns "On-site (5 days/week)" when days_in_office is 5' do
        expect(build(:job_application, days_in_office: 5).arrangement_label).to eq('On-site (5 days/week)')
      end

      it 'returns "Unknown" when days_in_office is nil' do
        expect(build(:job_application, days_in_office: nil).arrangement_label).to eq('Unknown')
      end
    end
  end

  describe 'scopes' do
    it 'returns active applications (not rejected/withdrawn/ghosted)' do
      active = create(:job_application, status: :applied)
      _rejected = create(:job_application, status: :rejected)
      expect(JobApplication.active).to include(active)
      expect(JobApplication.active).not_to include(_rejected)
    end

    it 'returns terminal applications' do
      terminal = create(:job_application, status: :rejected)
      active = create(:job_application, status: :applied)
      expect(JobApplication.terminal).to include(terminal)
      expect(JobApplication.terminal).not_to include(active)
    end

    it 'applied_after returns applications on or after a given date' do
      old_job = create(:job_application, apply_date: '2026-01-01')
      new_job = create(:job_application, apply_date: '2026-03-01')
      results = JobApplication.applied_after('2026-02-01')
      expect(results).to include(new_job)
      expect(results).not_to include(old_job)
    end

    it 'applied_before returns applications on or before a given date' do
      old_job = create(:job_application, apply_date: '2026-01-01')
      new_job = create(:job_application, apply_date: '2026-03-01')
      results = JobApplication.applied_before('2026-02-01')
      expect(results).to include(old_job)
      expect(results).not_to include(new_job)
    end

    it 'applied_after includes applications on the boundary date' do
      boundary_job = create(:job_application, apply_date: '2026-02-01')
      results = JobApplication.applied_after('2026-02-01')
      expect(results).to include(boundary_job)
    end

    it 'applied_before includes applications on the boundary date' do
      boundary_job = create(:job_application, apply_date: '2026-02-01')
      results = JobApplication.applied_before('2026-02-01')
      expect(results).to include(boundary_job)
    end
  end
end
