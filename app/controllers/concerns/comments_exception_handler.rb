module CommentsExceptionHandler
  extend ActiveSupport::Concern

  class InvalidFormat < StandardError; end

  included do
    rescue_from CommentsExceptionHandler::InvalidFormat do |_error|
      render json: {
        message: "Invalid format to create a new body"
      }, status: :unprocessable_entity
    end
  end
end
