require "rails_helper"

RSpec.describe Auth::ClerkTokenVerifier do
  subject(:verifier) { described_class.new(env: env) }

  let(:env) { clerk_test_env }

  before { described_class.reset_jwks_cache! }

  describe "#verify! with CLERK_JWT_KEY" do
    it "returns the claims of a valid token" do
      claims = verifier.verify!(clerk_token)

      expect(claims).to include("sub" => "user_test123", "sid" => "sess_test123")
    end

    it "rejects a missing token" do
      expect { verifier.verify!(nil) }.to raise_error(described_class::InvalidToken)
    end

    it "rejects an expired token" do
      token = clerk_token("exp" => Time.now.to_i - 60)

      expect { verifier.verify!(token) }.to raise_error(described_class::InvalidToken, /expired/i)
    end

    it "rejects a token from another issuer" do
      token = clerk_token("iss" => "https://evil.example.com")

      expect { verifier.verify!(token) }.to raise_error(described_class::InvalidToken)
    end

    it "rejects a token signed with a different key" do
      token = clerk_token({}, key: OpenSSL::PKey::RSA.generate(2048))

      expect { verifier.verify!(token) }.to raise_error(described_class::InvalidToken)
    end

    it "rejects a token issued for another origin" do
      token = clerk_token("azp" => "https://other-site.example.com")

      expect { verifier.verify!(token) }.to raise_error(described_class::InvalidToken, /unauthorized party/)
    end

    it "rejects a token signed with HS256 using the public key as secret" do
      token = JWT.encode(
        { "iss" => ClerkTokenHelpers::CLERK_TEST_ISSUER, "sub" => "user_x", "exp" => Time.now.to_i + 60 },
        clerk_rsa_key.public_key.to_pem,
        "HS256"
      )

      expect { verifier.verify!(token) }.to raise_error(described_class::InvalidToken)
    end

    it "rejects a token without subject" do
      token = clerk_token("sub" => nil)

      expect { verifier.verify!(token) }.to raise_error(described_class::InvalidToken)
    end

    it "accepts any origin when no authorized parties are configured" do
      verifier = described_class.new(env: clerk_test_env("CLERK_AUTHORIZED_PARTIES" => ""))

      expect(verifier.verify!(clerk_token("azp" => "https://anything.example.com"))).to include("sub" => "user_test123")
    end
  end

  describe "#verify! with JWKS" do
    let(:env) { clerk_test_env("CLERK_JWT_KEY" => nil) }
    let(:jwks_body) do
      { keys: [ JWT::JWK.new(clerk_rsa_key.public_key, kid: "test-key").export ] }.to_json
    end
    let(:requests) { [] }
    let(:http_get) do
      lambda do |uri|
        requests << uri.to_s
        jwks_body
      end
    end

    subject(:verifier) { described_class.new(env: env, http_get: http_get) }

    it "verifies with the key published at the issuer's JWKS URL" do
      expect(verifier.verify!(clerk_token)).to include("sub" => "user_test123")
      expect(requests).to eq([ "#{ClerkTokenHelpers::CLERK_TEST_ISSUER}/.well-known/jwks.json" ])
    end

    it "caches the JWKS between verifications" do
      2.times { verifier.verify!(clerk_token) }

      expect(requests.size).to eq(1)
    end

    it "refetches the JWKS when the kid is unknown (key rotation)" do
      verifier.verify!(clerk_token)
      new_key = OpenSSL::PKey::RSA.generate(2048)
      rotated = { keys: [ JWT::JWK.new(new_key.public_key, kid: "rotated-key").export ] }.to_json
      allow(http_get).to receive(:call).and_return(rotated)

      claims = verifier.verify!(clerk_token({}, key: new_key, kid: "rotated-key"))

      expect(claims).to include("sub" => "user_test123")
      expect(http_get).to have_received(:call).once
    end

    it "fails closed when the JWKS cannot be loaded" do
      failing = described_class.new(env: env, http_get: ->(_uri) { raise SocketError, "offline" })

      expect { failing.verify!(clerk_token) }.to raise_error(described_class::InvalidToken, /JWKS/)
    end
  end

  it "raises a configuration error when CLERK_ISSUER is missing" do
    verifier = described_class.new(env: clerk_test_env("CLERK_ISSUER" => nil))

    expect { verifier.verify!(clerk_token) }.to raise_error(described_class::ConfigurationError)
  end
end
