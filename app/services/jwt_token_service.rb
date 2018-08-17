class JwtTokenService
  class DecodeError < StandardError; end
  class ExpiredError < StandardError; end

  class << self
    def encode_token(payload)
      exp_time = Time.current + Settings.api_session_duration.to_i.minutes
      exp_payload = { data: payload, exp: exp_time.to_i }
      JWT.encode(exp_payload, private_key)
    end

    def decode_token(token)
      JWT.decode(token, private_key, true)
         .first
         .with_indifferent_access
    rescue JWT::ExpiredSignature => e
      raise ExpiredError, e.message
    rescue JWT::DecodeError => e
      raise DecodeError, e.message
    end

    def private_key
      Rails.application.secrets.secret_key_base
    end
  end
end
