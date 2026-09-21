module WorldClock
  class CandidateReviewsController < ApplicationController
    skip_forgery_protection
    def create
      form = EventCandidatesForm.new({ instants: params[:instants] })
      if form.valid?
        render json: { instants: form.normalized_instants.map(&:iso8601) }
      else
        render json: { errors: form.errors.full_messages }, status: :unprocessable_content
      end
    end
  end
end
