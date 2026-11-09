module Api
  module V1
    # Base class for authenticated API endpoints. Every action requires a valid
    # Clerk session token in the `Authorization: Bearer <token>` header.
    class BaseController < ApplicationController
      before_action :authenticate_request!

      attr_reader :current_token_claims

      private

      def authenticate_request!
        @current_token_claims = Auth::ClerkTokenVerifier.new.verify!(bearer_token)
      rescue Auth::ClerkTokenVerifier::InvalidToken
        render json: { error: "unauthorized" }, status: :unauthorized
      rescue Auth::ClerkTokenVerifier::ConfigurationError => e
        Rails.logger.error("[auth] #{e.message}")
        render json: { error: "authentication_unavailable" }, status: :service_unavailable
      end

      def bearer_token
        scheme, token = request.authorization.to_s.split(" ", 2)
        token if scheme&.casecmp?("Bearer")
      end

      # Clerk user id (`sub` claim), e.g. "user_2abc...".
      def current_clerk_user_id
        current_token_claims&.fetch("sub", nil)
      end
    end
  end
end
