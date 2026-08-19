require "rails_helper"

RSpec.describe "Job Applications", type: :system do
  describe "GET /job_applications (index)" do
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
        companies = page.all("tbody tr").map { |row| row.find("td:first-child").text.strip }
        expect(companies).to eq([ "Acme Corp", "Globex" ])
      end

      it "has a link to create a new application" do
        expect(page).to have_link("New Job Application")
      end

      it "links each company name to its show page" do
        click_link "Acme Corp"
        expect(page).to have_current_path(job_application_path(active_app))
      end

      it "updates an application's status from the list" do
        select "Phone screen", from: "Status for Acme Corp"
        click_button "Update Acme Corp"

        expect(page).to have_text("Application status updated.")
        expect(active_app.reload.status).to eq("phone_screen")
      end
    end
  end

  describe "GET /job_applications/:id (show)" do
    let!(:job) do
      create(:job_application,
        company: "Initech",
        role_title: "Platform Engineer",
        job_type: "SRE",
        location: "Austin, TX",
        days_in_office: 3,
        source: "LinkedIn",
        status: :phone_screen,
        apply_date: Date.new(2026, 4, 1),
        job_posting_url: "https://example.com/job",
        notes: "Looks promising")
    end

    before { visit job_application_path(job) }

    it "shows the company name" do
      expect(page).to have_text("Initech")
    end

    it "shows the role title" do
      expect(page).to have_text("Platform Engineer")
    end

    it "shows the status" do
      expect(page).to have_text("phone_screen")
    end

    it "shows the arrangement label" do
      expect(page).to have_text("Hybrid (3 days/week)")
    end

    it "shows the apply date" do
      expect(page).to have_text("2026-04-01")
    end

    it "shows the notes" do
      expect(page).to have_text("Looks promising")
    end

    it "has an edit link" do
      expect(page).to have_link("Edit")
    end

    it "has a delete button" do
      expect(page).to have_button("Delete")
    end

    context "with associated records" do
      let!(:stage) do
        create(:interview_stage, job_application: job,
          stage_type: :technical_screen, outcome: :passed)
      end

      let!(:contact) do
        create(:contact, job_application: job,
          name: "Jane Recruiter", role: :recruiter)
      end

      let!(:follow_up) do
        create(:follow_up, job_application: job,
          due_date: 2.days.from_now, description: "Send thank-you note",
          completed: false)
      end

      before { visit job_application_path(job) }

      it "shows interview stages" do
        expect(page).to have_text("technical_screen")
      end

      it "shows contacts" do
        expect(page).to have_text("Jane Recruiter")
      end

      it "shows pending follow-ups" do
        expect(page).to have_text("Send thank-you note")
      end
    end
  end

  describe "GET /job_applications/new + POST /job_applications (create)" do
    before { visit new_job_application_path }

    it "shows the new application form" do
      expect(page).to have_text("New Job Application")
    end

    context "with valid data" do
      it "creates a new application and redirects to show" do
        fill_in "Company", with: "Umbrella Corp"
        fill_in "Role title", with: "DevOps Engineer"
        fill_in "Apply date", with: "2026-04-15"
        click_button "Save"

        expect(page).to have_text("Umbrella Corp")
        expect(page).to have_text("Application created.")
      end
    end

    context "with missing required company" do
      it "re-renders the form with an error" do
        fill_in "Apply date", with: "2026-04-15"
        click_button "Save"

        expect(page).to have_text("Company can't be blank")
      end
    end
  end

  describe "GET /job_applications/:id/edit + PATCH /job_applications/:id (update)" do
    let!(:job) do
      create(:job_application, company: "Old Co", apply_date: Date.new(2026, 1, 1))
    end

    before { visit edit_job_application_path(job) }

    it "shows the edit form pre-filled with existing data" do
      expect(page).to have_field("Company", with: "Old Co")
    end

    context "with valid data" do
      it "updates the application and redirects to show" do
        fill_in "Company", with: "New Co"
        click_button "Save"

        expect(page).to have_text("New Co")
        expect(page).to have_text("Application updated.")
      end
    end

    context "with missing required company" do
      it "re-renders the form with an error" do
        fill_in "Company", with: ""
        click_button "Save"

        expect(page).to have_text("Company can't be blank")
      end
    end
  end

  describe "DELETE /job_applications/:id (destroy)" do
    let!(:job) { create(:job_application, company: "Doomed Co") }

    it "deletes the application and redirects to index" do
      visit job_application_path(job)
      click_button "Delete"

      expect(page).to have_current_path(job_applications_path)
      expect(page).to have_text("Application deleted.")
      expect(page).not_to have_text("Doomed Co")
    end
  end
end
