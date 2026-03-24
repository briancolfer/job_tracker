require 'rails_helper'

RSpec.describe Contact, type: :model do
  describe 'validations' do
    it 'is valid with a name and job_application' do
      contact = build(:contact)
      expect(contact).to be_valid
    end

    it 'is invalid without a name' do
      contact = build(:contact, name: nil)
      expect(contact).not_to be_valid
      expect(contact.errors[:name]).to include("can't be blank")
    end

    it 'is invalid without a job_application' do
      contact = build(:contact, job_application: nil)
      expect(contact).not_to be_valid
    end
  end

  describe 'role enum' do
    it 'defaults to recruiter' do
      contact = build(:contact)
      expect(contact.role).to eq('recruiter')
    end

    it 'supports all role types' do
      %i[recruiter hiring_manager interviewer other].each do |role|
        contact = build(:contact, role: role)
        expect(contact).to be_valid
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
