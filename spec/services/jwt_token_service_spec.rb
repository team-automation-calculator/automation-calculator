require 'rails_helper'

# JwtTokenService signs API tokens with plain HS256 and the app's
# secret_key_base. jwt 3 decodes Base64 strictly (RFC 4648), rejects an
# empty HMAC key when signing, and reorganised its errors under
# JWT::Error; every class JwtTokenService rescues still exists and still
# covers what it did under jwt 2.
RSpec.describe JwtTokenService do
  include ActiveSupport::Testing::TimeHelpers

  let(:payload) { { user_id: 42 } }
  let(:token) { described_class.encode_token(payload) }
  let(:session_duration) { Settings.api_session_duration.to_i.minutes }

  describe '.encode_token' do
    it 'returns a three-segment compact JWS' do
      expect(token.split('.').size).to eq(3)
    end

    it 'signs with HS256' do
      header = JSON.parse(Base64.urlsafe_decode64(token.split('.').first))
      expect(header['alg']).to eq('HS256')
    end

    it 'sets exp to api_session_duration minutes from now' do
      freeze_time do
        exp = JWT.decode(token, nil, false).first['exp']
        expect(exp).to eq((Time.current + session_duration).to_i)
      end
    end
  end

  describe '.decode_token' do
    subject(:decoded) { described_class.decode_token(token) }

    it 'round-trips the payload under :data' do
      expect(decoded[:data]).to eq('user_id' => 42)
    end

    it 'is indifferent to key type' do
      expect(decoded['data']['user_id']).to eq(42)
    end

    it 'exposes the exp claim' do
      expect(decoded[:exp]).to be_an(Integer)
    end

    context 'when the token has expired' do
      it 'raises ExpiredError' do
        issued = token
        travel(session_duration + 1.second) do
          expect { described_class.decode_token(issued) }
            .to raise_error(described_class::ExpiredError)
        end
      end
    end

    context 'when the signature has been tampered with' do
      let(:tampered) do
        header, body, signature = token.split('.')
        flipped = signature[0] == 'A' ? 'B' : 'A'
        [header, body, flipped + signature[1..]].join('.')
      end

      it 'raises DecodeError' do
        expect { described_class.decode_token(tampered) }
          .to raise_error(described_class::DecodeError)
      end
    end

    context 'when the payload has been tampered with' do
      let(:tampered) do
        header, _body, signature = token.split('.')
        forged = Base64.urlsafe_encode64({ data: { user_id: 1 } }.to_json,
                                         padding: false)
        [header, forged, signature].join('.')
      end

      it 'raises DecodeError' do
        expect { described_class.decode_token(tampered) }
          .to raise_error(described_class::DecodeError)
      end
    end

    # jwt 3 decodes Base64 strictly (RFC 4648). A token copied with a
    # trailing newline, which jwt 2's lenient RFC 2045 decoding accepted,
    # is now rejected like any other malformed token. The API reads the
    # token from a request header, which cannot carry a newline, so
    # nothing in the app depends on either behaviour.
    context 'when the token carries a trailing newline' do
      it 'raises DecodeError' do
        expect { described_class.decode_token("#{token}\n") }
          .to raise_error(described_class::DecodeError)
      end
    end

    context 'when the token carries surrounding whitespace' do
      it 'raises DecodeError' do
        expect { described_class.decode_token(" #{token} ") }
          .to raise_error(described_class::DecodeError)
      end
    end

    context 'when the token is missing' do
      it 'raises DecodeError for nil' do
        expect { described_class.decode_token(nil) }
          .to raise_error(described_class::DecodeError)
      end

      it 'raises DecodeError for an empty string' do
        expect { described_class.decode_token('') }
          .to raise_error(described_class::DecodeError)
      end
    end

    context 'when the token is not a JWT at all' do
      it 'raises DecodeError' do
        expect { described_class.decode_token('not.a.jwt') }
          .to raise_error(described_class::DecodeError)
      end
    end

    context 'when the token was signed with a different key' do
      let(:foreign) { JWT.encode({ data: payload }, 'x' * 64, 'HS256') }

      it 'raises DecodeError' do
        expect { described_class.decode_token(foreign) }
          .to raise_error(described_class::DecodeError)
      end
    end

    context 'when the token is unsigned (alg none)' do
      let(:unsigned) { JWT.encode({ data: payload }, nil, 'none') }

      it 'raises DecodeError' do
        expect { described_class.decode_token(unsigned) }
          .to raise_error(described_class::DecodeError)
      end
    end
  end

  describe '.private_key' do
    it 'is the secret_key_base, which the test environment sets from ENV' do
      expect(described_class.private_key)
        .to eq(ENV.fetch('SECRET_KEY_BASE'))
    end

    it 'is long enough for HS256' do
      expect(described_class.private_key.bytesize).to be >= 32
    end
  end
end
