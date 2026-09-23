class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  def render_not_found
    if request.format.json?
      render json: { error: "Not found" }, status: :not_found
    else
      render template: "errors/not_found", status: :not_found
    end
  end
end
