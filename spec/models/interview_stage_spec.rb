require 'rails_helper'

RSpec.describe InterviewStage, type: :model do
  describe 'validations' do
    it 'is valid with a stage_type and job_application' do
      stage = build(:interview_stage)
      expect(stage).to be_valid
    end

    it 'is invalid without a stage_type' do
      stage = build(:interview_stage, stage_type: nil)
      expect(stage).not_to be_valid
      expect(stage.errors[:stage_type]).to include("can't be blank")
    end

    it 'is invalid without a job_application' do
      stage = build(:interview_stage, job_application: nil)
      expect(stage).not_to be_valid
    end
  end

  describe 'stage_type enum' do
    it 'supports all stage types' do
      %i[phone_screen technical_screen onsite offer].each do |type|
        stage = build(:interview_stage, stage_type: type)
        expect(stage).to be_valid
      end
    end
  end

  describe 'outcome enum' do
    it 'defaults to pending' do
      stage = build(:interview_stage)
      expect(stage.outcome).to eq('pending')
    end

    it 'supports passed and failed outcomes' do
      %i[pending passed failed].each do |outcome|
        stage = build(:interview_stage, outcome: outcome)
        expect(stage.outcome).to eq(outcome.to_s)
      end
    end
  end

  describe 'associations' do
    it 'belongs to a job_application' do
      association = described_class.reflect_on_association(:job_application)
      expect(association.macro).to eq(:belongs_to)
    end
  end
end
