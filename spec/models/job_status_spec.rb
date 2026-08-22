require "rails_helper"

RSpec.describe JobStatus, type: :model do
  before { described_class.delete_all }

  describe "validations" do
    subject(:job_status) do
      described_class.new(code: "final_interview", value: 13, label: "Final Interview")
    end

    it { is_expected.to be_valid }

    it "requires a lowercase snake_case code" do
      job_status.code = "Final Interview"

      expect(job_status).not_to be_valid
      expect(job_status.errors[:code]).to include("must use lowercase snake_case")
    end

    it "requires unique codes and integer values" do
      described_class.create!(code: "existing", value: 13, label: "Existing")

      expect(job_status).not_to be_valid
      expect(job_status.errors[:value]).to include("has already been taken")
    end
  end

  describe ".add" do
    it "creates a status with the next unused integer value" do
      described_class.create!(code: "applied", value: 1, label: "Applied", default: true)
      described_class.create!(code: "rejected", value: 7, label: "Rejected", terminal: true)

      added = described_class.add("final_interview", label: "Final Interview")

      expect(added).to have_attributes(
        code: "final_interview",
        value: 8,
        label: "Final Interview",
        terminal: false
      )
    end
  end

  describe "#update_definition" do
    it "renames a code without changing its integer value" do
      status = described_class.create!(code: "applied", value: 1, label: "Applied", default: true)

      status.update_definition(new_code: "submitted", label: "Submitted")

      expect(status.reload).to have_attributes(
        code: "submitted",
        value: 1,
        label: "Submitted",
        default: true
      )
    end
  end
end
