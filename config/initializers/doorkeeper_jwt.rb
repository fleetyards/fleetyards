Doorkeeper::JWT.configure do
  token_payload do |opts|
    user = User.find(opts[:resource_owner_id])

    {
      iss: "FleetYards",
      iat: Time.current.utc.to_i,
      aud: opts[:application][:uid],

      # @see JWT reserved claims - https://tools.ietf.org/html/draft-jones-json-web-token-07#page-7
      jti: SecureRandom.uuid,
      sub: user.id,

      user: {
        id: user.id,
        username: user.username,
        email: user.email
      }
    }
  end

  # Optionally set additional headers for the JWT. See
  # https://tools.ietf.org/html/rfc7515#section-4.1
  # JWK can be used to automatically verify RS* tokens client-side if token's kid matches a public kid in /oauth/discovery/keys
  # token_headers do |_opts|
  #   key = OpenSSL::PKey::RSA.new(File.read(File.join('path', 'to', 'file.pem')))
  #   { kid: JWT::JWK.new(key)[:kid] }
  # end

  # Use the application secret specified in the access grant token. Defaults to
  # `false`. If you specify `use_application_secret true`, both `secret_key` and
  # `secret_key_path` will be ignored.
  use_application_secret false

  # Set the encryption secret. This would be shared with any other applications
  # that should be able to read the payload of the token. Defaults to "secret".
  secret_key Rails.application.credentials.doorkeeper.jwt_secret

  # If you want to use RS* encoding specify the path to the RSA key to use for
  # signing. If you specify a `secret_key_path` it will be used instead of
  # `secret_key`.
  # secret_key_path File.join('path', 'to', 'file.pem')

  signing_method :hs512
end
