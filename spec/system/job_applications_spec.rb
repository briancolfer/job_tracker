require "rails_helper"

RSpec.describe "Job Applications dashboard", type: :system do
  describe "GET /job_applications" do
    context "when there are no job applications" do
      it "shows the page heading and an empty state message" do
        visit job_applications_path

        expect(page).to have_text("Job Applications")
        expect(page).to have_text("No job applications found")
      end
    end

    context "when job applications exist" do
      let!(:active_app) do
        create(:job_application,
          company: "Acme Corp",
          role_title: "Site Reliability Engineer",
          status: :applied,
          apply_date: Date.new(2026, 3, 1))
      end

      let!(:rejected_app) do
        create(:job_application,
          company: "Globex",
          role_title: "DevOps Engineer",
          status: :rejected,
          apply_date: Date.new(2026, 2, 15))
      end

      before { visit job_applications_path }

      it "shows the page heading" do
        expect(page).to have_text("Job Applications")
      end

      it "lists every application with its company name" do
        expect(page).to have_text("Acme Corp")
        expect(page).to have_text("Globex")
      end

      it "shows the role title for each application" do
        expect(page).to have_text("Site Reliability Engineer")
        expect(page).to have_text("DevOps Engineer")
      end

      it "shows the status for each application" do
        expect(page).to have_text("applied")
        expect(page).to have_text("rejected")
      end

      it "shows the apply date for each application" do
        expect(page).to have_text("2026-03-01")
        expect(page).to have_text("2026-02-15")
      end

      it "lists applications in reverse chronological order" do
        companies = page.all("tbody tr").map { |row| row.find("td:first-child").text }
        expect(companies).to eq([ "Acme Corp", "Globex" ])
      end
    end
  end
end
