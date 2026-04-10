class JobApplicationsController < ApplicationController
  def index
    @job_applications = JobApplication.order(apply_date: :desc)
  end
end
