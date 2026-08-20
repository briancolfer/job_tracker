require "rails_helper"

RSpec.describe "API::V1::JobApplications", type: :request do
  describe "GET /api/v1/job_applications" do
    it "returns job applications as JSON" do
      job = create(:job_application, company: "Acme Corp", status: :phone_screen)

      get api_v1_job_applications_path

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(
        a_hash_including("id" => job.id, "company" => "Acme Corp", "status" => "phone_screen")
      )
    end
  end

  describe "GET /api/v1/job_applications/:id" do
    it "returns one job application as JSON" do
      job = create(:job_application, company: "Initech", days_in_office: 3)

      get api_v1_job_application_path(job)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(
        "id" => job.id,
        "company" => "Initech",
        "days_in_office" => 3,
        "arrangement" => "Hybrid (3 days/week)",
        "status_label" => "Applied"
      )
    end

    it "returns JSON not found for an unknown job application" do
      get api_v1_job_application_path(999_999)

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to eq("error" => "Job application not found")
    end
  end

  describe "PATCH /api/v1/job_applications/:id" do
    it "updates permitted job fields" do
      job = create(:job_application, company: "Old Co", status: :applied)

      patch api_v1_job_application_path(job), params: {
        job_application: { company: "New Co", status: "offer_received" }
      }, as: :json

      expect(response).to have_http_status(:ok)
      expect(job.reload).to have_attributes(company: "New Co", status: "offer_received")
      expect(response.parsed_body).to include("company" => "New Co", "status" => "offer_received")
    end

    it "returns validation errors without changing the job" do
      job = create(:job_application, company: "Acme Corp", status: :applied)

      patch api_v1_job_application_path(job), params: {
        job_application: { company: "", status: "not_a_status" }
      }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.fetch("errors")).to include("Company can't be blank", "Status is not included in the list")
      expect(job.reload).to have_attributes(company: "Acme Corp", status: "applied")
    end
  end

  describe "GET /api/v1/statuses" do
    it "returns the supported pipeline statuses" do
      get api_v1_statuses_path

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(JobApplication.statuses.keys)
    end
  end
end
