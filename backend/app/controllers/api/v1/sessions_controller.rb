module Api
  module V1
    # Lets the frontend confirm that its Clerk token is accepted by the API.
    class SessionsController < BaseController
      def show
        render json: {
          clerk_user_id: current_clerk_user_id,
          session_id: current_token_claims["sid"],
          expires_at: Time.at(current_token_claims["exp"]).utc.iso8601
        }
      end
    end
  end
end
