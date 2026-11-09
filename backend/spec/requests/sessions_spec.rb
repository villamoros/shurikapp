require "rails_helper"

RSpec.describe "Session", type: :request do
  before do
    Auth::ClerkTokenVerifier.reset_jwks_cache!
    clerk_test_env.each { |key, value| stub_env(key, value) }
  end

  def stub_env(key, value)
    allow(ENV).to receive(:[]).and_call_original unless @env_stubbed
    @env_stubbed = true
    allow(ENV).to receive(:[]).with(key).and_return(value)
  end

  it "returns 401 without a token" do
    get "/api/v1/session"

    expect(response).to have_http_status(:unauthorized)
  end

  it "returns 401 with a token that is not a valid Clerk JWT" do
    get "/api/v1/session", headers: { "Authorization" => "Bearer not-a-jwt" }

    expect(response).to have_http_status(:unauthorized)
  end

  it "returns the Clerk user with a valid token" do
    get "/api/v1/session", headers: { "Authorization" => "Bearer #{clerk_token}" }

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include("clerk_user_id" => "user_test123", "session_id" => "sess_test123")
  end

  it "returns 503 when Clerk is not configured" do
    stub_env("CLERK_ISSUER", nil)

    get "/api/v1/session", headers: { "Authorization" => "Bearer #{clerk_token}" }

    expect(response).to have_http_status(:service_unavailable)
  end
end
