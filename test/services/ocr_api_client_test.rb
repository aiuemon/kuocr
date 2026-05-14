require "test_helper"

class OcrApiClientTest < ActiveSupport::TestCase
  setup do
    Setting.ocr_endpoint = "https://ocr.example.com/api/generate"
    Setting.ocr_skip_ssl_verify = false
  end

  test "build_http_client does not skip SSL verification by default" do
    client = OcrApiClient.new
    uri = URI.parse("https://ocr.example.com/api/generate")
    http = client.send(:build_http_client, uri)

    assert http.use_ssl?
    assert_not_equal OpenSSL::SSL::VERIFY_NONE, http.verify_mode
  end

  test "build_http_client skips SSL verification when ocr_skip_ssl_verify is true" do
    Setting.ocr_skip_ssl_verify = true
    client = OcrApiClient.new
    uri = URI.parse("https://ocr.example.com/api/generate")
    http = client.send(:build_http_client, uri)

    assert http.use_ssl?
    assert_equal OpenSSL::SSL::VERIFY_NONE, http.verify_mode
  end

  test "build_http_client does not set verify_mode for http scheme" do
    Setting.ocr_endpoint = "http://ocr.example.com/api/generate"
    Setting.ocr_skip_ssl_verify = false
    client = OcrApiClient.new
    uri = URI.parse("http://ocr.example.com/api/generate")
    http = client.send(:build_http_client, uri)

    assert_not http.use_ssl?
  end
end
