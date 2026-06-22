require "test_helper"

class SettingTest < ActiveSupport::TestCase
  setup do
    Rails.cache.clear
  end

  test "auth settings have correct defaults" do
    assert_equal true, Setting.local_auth_enabled
    assert_equal true, Setting.local_auth_show_on_login
    assert_equal false, Setting.self_signup_enabled
  end

  test "auth boolean methods work" do
    Setting.local_auth_enabled = false
    assert_not Setting.local_auth_enabled?

    Setting.local_auth_enabled = true
    assert Setting.local_auth_enabled?
  end

  test "ocr settings have correct defaults" do
    assert_equal "", Setting.ocr_endpoint
    assert_equal 300, Setting.ocr_timeout
    assert_equal false, Setting.ocr_skip_ssl_verify
  end

  test "ocr_configured? returns false without endpoint and model" do
    Setting.ocr_endpoint = ""
    Setting.ocr_model = ""
    assert_not Setting.ocr_configured?
  end

  test "ocr_configured? returns true with endpoint and model" do
    Setting.ocr_endpoint = "http://example.com/api"
    Setting.ocr_model = "llava:latest"
    assert Setting.ocr_configured?
  end

  test "effective_ocr_timeout returns default when not set" do
    Setting.ocr_timeout = 0
    assert_equal Setting::DEFAULT_OCR_TIMEOUT, Setting.effective_ocr_timeout
  end

  test "effective_ocr_options returns default when empty" do
    Setting.ocr_options = {}
    assert_equal Setting::DEFAULT_OCR_OPTIONS, Setting.effective_ocr_options
  end

  test "quota settings have correct default" do
    assert_equal 1024, Setting.max_storage_per_user_mb
  end

  test "max_storage_bytes converts mb to bytes" do
    Setting.max_storage_per_user_mb = 100
    assert_equal 100.megabytes, Setting.max_storage_bytes
  end

  test "timeout_for_auth_method returns specific timeout when set" do
    Setting.session_timeout_hours = 24
    Setting.session_timeout_local_hours = 12
    assert_equal 12.hours, Setting.timeout_for_auth_method("local")
  end

  test "timeout_for_auth_method returns default timeout when not set" do
    Setting.session_timeout_hours = 24
    Setting.session_timeout_local_hours = nil
    assert_equal 24.hours, Setting.timeout_for_auth_method("local")
  end

  test "timeout_for_auth_method supports all auth methods" do
    Setting.session_timeout_hours = 24
    Setting.session_timeout_local_hours = 1
    Setting.session_timeout_saml_hours = 2
    Setting.session_timeout_oidc_hours = 3
    Setting.session_timeout_passkey_hours = 4

    assert_equal 1.hours, Setting.timeout_for_auth_method("local")
    assert_equal 2.hours, Setting.timeout_for_auth_method("saml")
    assert_equal 3.hours, Setting.timeout_for_auth_method("oidc")
    assert_equal 4.hours, Setting.timeout_for_auth_method("passkey")
  end

  test "timeout_for_auth_method returns default for unknown auth method" do
    Setting.session_timeout_hours = 24
    assert_equal 24.hours, Setting.timeout_for_auth_method("unknown")
    assert_equal 24.hours, Setting.timeout_for_auth_method(nil)
  end

  test "priority_for_affiliations returns 3 when affiliations blank" do
    Setting.affiliation_priority_map = { "faculty" => 1 }
    assert_equal 3, Setting.priority_for_affiliations([])
    assert_equal 3, Setting.priority_for_affiliations(nil)
  end

  test "priority_for_affiliations returns 3 when map is empty" do
    Setting.affiliation_priority_map = {}
    assert_equal 3, Setting.priority_for_affiliations(["faculty"])
  end

  test "priority_for_affiliations returns mapped priority" do
    Setting.affiliation_priority_map = { "faculty" => 1, "staff" => 2 }
    assert_equal 1, Setting.priority_for_affiliations(["faculty"])
    assert_equal 2, Setting.priority_for_affiliations(["staff"])
  end

  test "priority_for_affiliations returns minimum priority for multiple affiliations" do
    Setting.affiliation_priority_map = { "faculty" => 1, "member" => 3 }
    assert_equal 1, Setting.priority_for_affiliations(["member", "faculty"])
  end

  test "priority_for_affiliations returns 3 when no affiliation matches map" do
    Setting.affiliation_priority_map = { "faculty" => 1 }
    assert_equal 3, Setting.priority_for_affiliations(["unknown"])
  end

  test "priority_for_affiliations ignores out-of-range values in map" do
    Setting.affiliation_priority_map = { "bad" => 0, "faculty" => 2 }
    assert_equal 2, Setting.priority_for_affiliations(["bad", "faculty"])
  end
end
