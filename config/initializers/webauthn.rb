WebAuthn.configure do |config|
  config.allowed_origins = [ ENV.fetch("WEBAUTHN_ORIGIN") { "http://localhost:3000" } ]
  config.rp_name = "kuocr"
  # rp_id は origin から自動推論される
end
