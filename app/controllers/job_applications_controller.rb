class JobApplicationsController < ApplicationController
  before_action :set_job_application, only: [ :show, :edit, :update, :update_status, :destroy ]

  def index
    @job_applications = JobApplication.order(apply_date: :desc)
  end

  def show
  end

  def new
    @job_application = JobApplication.new(apply_date: Date.today)
  end

  def create
    @job_application = JobApplication.new(job_application_params)
    if @job_application.save
      redirect_to @job_application, notice: "Application created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @job_application.update(job_application_params)
      redirect_to @job_application, notice: "Application updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def update_status
    if @job_application.update(status_params)
      redirect_to job_applications_path, notice: "Application status updated."
    else
      redirect_to job_applications_path, alert: @job_application.errors.full_messages.to_sentence
    end
  end

  def destroy
    @job_application.destroy
    redirect_to job_applications_path, notice: "Application deleted."
  end

  private

  def set_job_application
    @job_application = JobApplication.find(params[:id])
  end

  def job_application_params
    params.require(:job_application).permit(
      :company, :role_title, :job_type, :location, :days_in_office,
      :source, :status, :apply_date, :job_posting_url, :notes
    )
  end

  def status_params
    params.require(:job_application).permit(:status)
  end
end
