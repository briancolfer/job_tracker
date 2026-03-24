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
  end
end
