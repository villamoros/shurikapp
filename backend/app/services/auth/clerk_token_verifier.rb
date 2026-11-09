require "json"
require "net/http"
require "uri"

module Auth
  # Verifies Clerk session tokens (RS256 JWTs) sent by the frontend as
  # `Authorization: Bearer <token>`.
  #
  # Configuration (environment variables):
  #
  # - CLERK_ISSUER (required): the Clerk Frontend API URL, e.g.
  #   https://your-app.clerk.accounts.dev. Must match the token's `iss` claim.
  # - CLERK_JWT_KEY (optional): the PEM public key from the Clerk dashboard
  #   (API Keys > Show JWT public key). When present, tokens are verified
  #   without any network call.
  # - CLERK_JWKS_URL (optional): defaults to "#{CLERK_ISSUER}/.well-known/jwks.json".
  #   Used only when CLERK_JWT_KEY is not set.
  # - CLERK_AUTHORIZED_PARTIES (optional): comma-separated origins allowed in the
  #   `azp` claim. Defaults to FRONTEND_URL. Leave both empty to skip the check.
  class ClerkTokenVerifier
    class InvalidToken < StandardError; end
    class ConfigurationError < StandardError; end

    ALGORITHMS = [ "RS256" ].freeze
    JWKS_TTL_SECONDS = 3600
    LEEWAY_SECONDS = 5

    @jwks_mutex = Mutex.new
    @jwks_cache = {}

    class << self
      attr_reader :jwks_mutex, :jwks_cache

      def reset_jwks_cache!
        jwks_mutex.synchronize { jwks_cache.clear }
      end
    end

    def initialize(env: ENV, http_get: nil)
      @issuer = presence(env["CLERK_ISSUER"])&.delete_suffix("/")
      @jwt_key = presence(env["CLERK_JWT_KEY"])
      @jwks_url = presence(env["CLERK_JWKS_URL"]) || (@issuer && "#{@issuer}/.well-known/jwks.json")
      @authorized_parties = parse_list(env["CLERK_AUTHORIZED_PARTIES"] || env["FRONTEND_URL"])
      @http_get = http_get || method(:default_http_get)
    end

    # Returns the verified claims (a Hash with string keys) or raises InvalidToken.
    def verify!(token)
      raise InvalidToken, "missing token" if presence(token).nil?
      raise ConfigurationError, "CLERK_ISSUER is not configured" if @issuer.nil?

      claims, = JWT.decode(token, verification_key, true, decode_options)
      verify_authorized_party!(claims)
      raise InvalidToken, "missing subject" if presence(claims["sub"]).nil?

      claims
    rescue JWT::DecodeError => e
      raise InvalidToken, e.message
    end

    private

    def decode_options
      options = {
        algorithms: ALGORITHMS,
        iss: @issuer,
        verify_iss: true,
        verify_iat: true,
        leeway: LEEWAY_SECONDS
      }
      options[:jwks] = method(:load_jwks) if @jwt_key.nil?
      options
    end

    def verification_key
      return nil if @jwt_key.nil?

      OpenSSL::PKey::RSA.new(@jwt_key.gsub("\\n", "\n"))
    rescue OpenSSL::PKey::PKeyError => e
      raise ConfigurationError, "CLERK_JWT_KEY is not a valid RSA public key: #{e.message}"
    end

    # Loader used by ruby-jwt. It receives `invalidate: true` (or `kid_not_found`)
    # when no key matches the token's `kid`, which happens after Clerk rotates keys.
    def load_jwks(options = {})
      refresh = options[:invalidate] || options[:kid_not_found]

      self.class.jwks_mutex.synchronize do
        cached = self.class.jwks_cache[@jwks_url]
        fresh = cached && (monotonic_now - cached[:fetched_at]) < JWKS_TTL_SECONDS
        return cached[:jwks] if fresh && !refresh

        jwks = fetch_jwks
        self.class.jwks_cache[@jwks_url] = { jwks: jwks, fetched_at: monotonic_now }
        jwks
      end
    end

    def fetch_jwks
      body = @http_get.call(URI(@jwks_url))
      jwks = JSON.parse(body, symbolize_names: true)
      raise InvalidToken, "JWKS has no keys" unless jwks[:keys].is_a?(Array)

      jwks
    rescue JSON::ParserError, SocketError, SystemCallError, Timeout::Error, Net::HTTPError => e
      raise InvalidToken, "could not load Clerk JWKS: #{e.message}"
    end

    def default_http_get(uri)
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                                 open_timeout: 5, read_timeout: 5) do |http|
        http.get(uri.request_uri)
      end
      raise Net::HTTPError.new("HTTP #{response.code}", response) unless response.is_a?(Net::HTTPSuccess)

      response.body
    end

    def verify_authorized_party!(claims)
      return if @authorized_parties.empty?
      return if claims["azp"].nil? # Clerk omits azp for some backend-issued tokens.
      return if @authorized_parties.include?(claims["azp"])

      raise InvalidToken, "unauthorized party: #{claims["azp"]}"
    end

    def parse_list(value)
      value.to_s.split(",").map { |item| item.strip.delete_suffix("/") }.reject(&:empty?)
    end

    def presence(value)
      value = value.to_s.strip
      value.empty? ? nil : value
    end

    def monotonic_now
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end
end
