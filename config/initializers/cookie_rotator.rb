# Be sure to restart your server when you modify this file.

# config.load_defaults 7.0 (config/application.rb) switches
# ActiveSupport::KeyGenerator from SHA1 to SHA256, so every key derived from
# secret_key_base changes and cookies written before the switch — the Devise
# session cookie and the visitor session (session[:visitor_id]) — could no
# longer be read. This rotator lets Rails keep reading SHA1-derived
# :encrypted and :signed cookies and rewrite them with the new keys on the
# first request, as described in the Rails 7.0 upgrade guide ("Key generator
# digest class changing to use SHA256").
#
# Temporary: remove once this release has been on production long enough
# for the old cookies to have been rewritten (planned for Phase 12 of
# version_dates/upgrade_path.json). If it misbehaves, the fallback is
# `config.active_support.key_generator_hash_digest_class = OpenSSL::Digest::SHA1`
# in config/application.rb, right after load_defaults.
#
# JWTs are unaffected: JwtTokenService signs with secret_key_base directly.
Rails.application.config.after_initialize do
  Rails.application.config.action_dispatch.cookies_rotations.tap do |cookies|
    dispatch = Rails.application.config.action_dispatch
    key_generator = ActiveSupport::KeyGenerator.new(
      Rails.application.secret_key_base,
      iterations: 1000,
      hash_digest_class: OpenSSL::Digest::SHA1
    )
    key_len = ActiveSupport::MessageEncryptor.key_len

    old_encrypted_secret = key_generator.generate_key(
      dispatch.authenticated_encrypted_cookie_salt, key_len
    )
    old_signed_secret = key_generator.generate_key(dispatch.signed_cookie_salt)

    cookies.rotate :encrypted, old_encrypted_secret
    cookies.rotate :signed, old_signed_secret
  end
end
