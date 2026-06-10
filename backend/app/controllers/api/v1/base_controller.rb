module Api
  module V1
    class BaseController < ApplicationController
      before_action :authenticate_request!

      private

      def authenticate_request!
        token = request.headers["Authorization"]&.to_s&.delete_prefix("Bearer ")
        render json: { error: "unauthorized" }, status: :unauthorized if token.blank?
      end
    end
  end
end

