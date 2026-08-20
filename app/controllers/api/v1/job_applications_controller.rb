module Api
  module V1
    class JobApplicationsController < ActionController::API
      before_action :set_job_application, only: [ :show, :update ]

      rescue_from ActiveRecord::RecordNotFound do
        render json: { error: "Job application not found" }, status: :not_found
      end

      def index
        job_applications = JobApplication.order(apply_date: :desc)

        render json: job_applications.map { |job_application| serialize(job_application) }
      end

      def show
        render json: serialize(@job_application)
      end

      def update
        if @job_application.update(job_application_params)
          render json: serialize(@job_application)
        else
          render json: { errors: @job_application.errors.full_messages }, status: :unprocessable_content
        end
      end

      def statuses
        render json: JobApplication.statuses.keys
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

      def serialize(job_application)
        job_application.as_json(
          only: [
            :id, :company, :role_title, :job_type, :location, :days_in_office,
            :source, :status, :apply_date, :job_posting_url, :notes, :created_at, :updated_at
          ]
        ).merge(
          "arrangement" => job_application.arrangement_label,
          "status_label" => job_application.status_label
        )
      end
    end
  end
end
