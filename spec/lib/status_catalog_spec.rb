require "rails_helper"
require "tmpdir"

RSpec.describe JobTracker::StatusCatalog do
  let(:config_path) { Pathname(Dir.mktmpdir).join("job_statuses.yml") }
  let(:initial_definitions) do
    {
      "applied" => { "value" => 1, "label" => "Applied", "terminal" => false, "default" => true },
      "rejected" => { "value" => 7, "label" => "Rejected", "terminal" => true }
    }
  end

  before { File.write(config_path, YAML.dump(initial_definitions)) }

  after { FileUtils.remove_entry(config_path.dirname) }

  describe ".enum_mapping" do
    it "returns stable integer values keyed by status code" do
      expect(described_class.enum_mapping(path: config_path)).to eq("applied" => 1, "rejected" => 7)
    end
  end

  describe ".add" do
    it "adds a status with the next unused integer and its display label" do
      described_class.add("final_interview", label: "Final Interview", path: config_path)

      expect(described_class.definition("final_interview", path: config_path)).to include(
        "value" => 8,
        "label" => "Final Interview",
        "terminal" => false
      )
    end

    it "can add a terminal status" do
      described_class.add("declined", label: "Declined", terminal: true, path: config_path)

      expect(described_class.definition("declined", path: config_path)).to include("terminal" => true)
    end

    it "rejects duplicate codes" do
      expect {
        described_class.add("applied", label: "Already Applied", path: config_path)
      }.to raise_error(JobTracker::StatusCatalog::ValidationError, /already exists/i)
    end

    it "rejects codes that are not lowercase snake case" do
      expect {
        described_class.add("Final Interview", label: "Final Interview", path: config_path)
      }.to raise_error(JobTracker::StatusCatalog::ValidationError, /lowercase snake_case/i)
    end

    it "requires a display label" do
      expect {
        described_class.add("final_interview", label: "", path: config_path)
      }.to raise_error(JobTracker::StatusCatalog::ValidationError, /label is required/i)
    end
  end

  describe ".update" do
    it "changes a display label without changing the integer value" do
      described_class.update("applied", label: "Application Sent", path: config_path)

      expect(described_class.definition("applied", path: config_path)).to include(
        "value" => 1,
        "label" => "Application Sent"
      )
    end

    it "renames a code without changing its integer value or default setting" do
      described_class.update("applied", new_code: "submitted", path: config_path)

      expect(described_class.definition("applied", path: config_path)).to be_nil
      expect(described_class.definition("submitted", path: config_path)).to include(
        "value" => 1,
        "default" => true
      )
    end

    it "updates whether a status is terminal" do
      described_class.update("applied", terminal: true, path: config_path)

      expect(described_class.definition("applied", path: config_path)).to include("terminal" => true)
    end

    it "rejects an unknown status code" do
      expect {
        described_class.update("missing", label: "Missing", path: config_path)
      }.to raise_error(JobTracker::StatusCatalog::ValidationError, /not found/i)
    end

    it "rejects a rename that conflicts with another code" do
      expect {
        described_class.update("applied", new_code: "rejected", path: config_path)
      }.to raise_error(JobTracker::StatusCatalog::ValidationError, /already exists/i)
    end
  end
end
