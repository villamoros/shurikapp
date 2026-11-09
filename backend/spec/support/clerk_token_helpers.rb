require "openssl"

# Builds Clerk-like session tokens signed with a throwaway RSA key, so specs
# never call Clerk.
module ClerkTokenHelpers
  CLERK_TEST_ISSUER = "https://shurikapp-test.clerk.accounts.dev".freeze
  CLERK_TEST_ORIGIN = "http://localhost:3000".freeze

  def clerk_rsa_key
    @clerk_rsa_key ||= OpenSSL::PKey::RSA.generate(2048)
  end

  def clerk_test_env(overrides = {})
    {
      "CLERK_ISSUER" => CLERK_TEST_ISSUER,
      "CLERK_JWT_KEY" => clerk_rsa_key.public_key.to_pem,
      "CLERK_AUTHORIZED_PARTIES" => CLERK_TEST_ORIGIN
    }.merge(overrides)
  end

  def clerk_token(claims = {}, key: clerk_rsa_key, kid: "test-key")
    now = Time.now.to_i
    payload = {
      "iss" => CLERK_TEST_ISSUER,
      "sub" => "user_test123",
      "sid" => "sess_test123",
      "azp" => CLERK_TEST_ORIGIN,
      "iat" => now,
      "nbf" => now - 5,
      "exp" => now + 60
    }.merge(claims)
    JWT.encode(payload, key, "RS256", { kid: kid })
  end
end

RSpec.configure do |config|
  config.include ClerkTokenHelpers
end
