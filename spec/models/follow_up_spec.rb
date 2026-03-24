require 'rails_helper'

RSpec.describe FollowUp, type: :model do
  describe 'validations' do
    it 'is valid with a due_date, description, and job_application' do
      follow_up = build(:follow_up)
      expect(follow_up).to be_valid
    end

    it 'is invalid without a due_date' do
      follow_up = build(:follow_up, due_date: nil)
      expect(follow_up).not_to be_valid
      expect(follow_up.errors[:due_date]).to include("can't be blank")
    end

    it 'is invalid without a description' do
      follow_up = build(:follow_up, description: nil)
      expect(follow_up).not_to be_valid
      expect(follow_up.errors[:description]).to include("can't be blank")
    end
  end

  describe 'scopes' do
    it 'returns only incomplete follow-ups as pending' do
      incomplete = create(:follow_up, completed: false)
      _complete = create(:follow_up, completed: true)
      expect(FollowUp.pending).to include(incomplete)
      expect(FollowUp.pending).not_to include(_complete)
    end

    it 'returns overdue follow-ups' do
      overdue = create(:follow_up, due_date: 3.days.ago, completed: false)
      future = create(:follow_up, due_date: 3.days.from_now, completed: false)
      expect(FollowUp.overdue).to include(overdue)
      expect(FollowUp.overdue).not_to include(future)
    end
  end

  describe 'associations' do
    it 'belongs to a job_application' do
      association = described_class.reflect_on_association(:job_application)
      expect(association.macro).to eq(:belongs_to)
    end
  end
end
