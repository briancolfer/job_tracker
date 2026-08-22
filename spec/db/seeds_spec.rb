require "rails_helper"

RSpec.describe "database seeds" do
  it "loads the current job status catalog idempotently" do
    JobStatus.delete_all

    2.times { Rails.application.load_seed }

    expect(JobStatus.order(:value).pluck(:code, :value, :label, :terminal, :default)).to eq([
      [ "cold_call", 0, "Cold Call", false, false ],
      [ "applied", 1, "Applied", false, true ],
      [ "phone_screen", 2, "Phone Screen", false, false ],
      [ "technical_screen", 3, "Technical Screen", false, false ],
      [ "onsite", 4, "On-site", false, false ],
      [ "offer_received", 5, "Offer Received", false, false ],
      [ "accepted", 6, "Accepted", true, false ],
      [ "rejected", 7, "Rejected", true, false ],
      [ "withdrawn", 8, "Withdrawn", true, false ],
      [ "ghosted", 9, "Ghosted", true, false ],
      [ "job_filled", 10, "Job filled", true, false ],
      [ "second_round", 11, "Second round", false, false ],
      [ "on_hold", 12, "On hold", true, false ]
    ])
  end
end
