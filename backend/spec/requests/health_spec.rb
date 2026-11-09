require "rails_helper"

RSpec.describe "Health", type: :request do
  it "responds without authentication" do
    get "/api/v1/health"

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include("status" => "ok")
  end

  it "exposes the Rails health check path" do
    get "/up"

    expect(response).to have_http_status(:ok)
  end
end
