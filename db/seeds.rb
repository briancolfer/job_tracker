job_statuses = [
  { code: "cold_call", value: 0, label: "Cold Call", terminal: false, default: false },
  { code: "applied", value: 1, label: "Applied", terminal: false, default: true },
  { code: "phone_screen", value: 2, label: "Phone Screen", terminal: false, default: false },
  { code: "technical_screen", value: 3, label: "Technical Screen", terminal: false, default: false },
  { code: "onsite", value: 4, label: "On-site", terminal: false, default: false },
  { code: "offer_received", value: 5, label: "Offer Received", terminal: false, default: false },
  { code: "accepted", value: 6, label: "Accepted", terminal: true, default: false },
  { code: "rejected", value: 7, label: "Rejected", terminal: true, default: false },
  { code: "withdrawn", value: 8, label: "Withdrawn", terminal: true, default: false },
  { code: "ghosted", value: 9, label: "Ghosted", terminal: true, default: false },
  { code: "job_filled", value: 10, label: "Job filled", terminal: true, default: false },
  { code: "second_round", value: 11, label: "Second round", terminal: false, default: false },
  { code: "on_hold", value: 12, label: "On hold", terminal: true, default: false }
]

job_statuses.each do |attributes|
  JobStatus.find_or_create_by!(value: attributes.fetch(:value)) do |status|
    status.assign_attributes(attributes)
  end
end
