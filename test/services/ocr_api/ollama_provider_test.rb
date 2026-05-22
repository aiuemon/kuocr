require "test_helper"

class OcrApi::OllamaProviderTest < ActiveSupport::TestCase
  setup do
    Setting.ocr_endpoint = "http://localhost:11434/api/generate"
    Setting.ocr_model = "llava:latest"
    Setting.ocr_skip_ssl_verify = false
    @provider = OcrApi::OllamaProvider.new(
      endpoint: Setting.ocr_endpoint,
      api_key: "",
      timeout: 30,
      skip_ssl_verify: false
    )
    @image_data = "fake_image_bytes"
    @prompt = "文字を起こしてください"
  end

  test "build_request sets Ollama-format payload" do
    uri = URI.parse(Setting.ocr_endpoint)
    request = @provider.send(:build_request, uri, @image_data, "image/jpeg", @prompt)

    payload = JSON.parse(request.body, symbolize_names: true)
    assert_equal "llava:latest", payload[:model]
    assert_equal @prompt, payload[:prompt]
    assert payload[:stream]
    assert_kind_of Array, payload[:images]
    assert_equal Base64.strict_encode64(@image_data), payload[:images][0]
    assert_kind_of Hash, payload[:options]
  end

  test "extract_text concatenates response fields from NDJSON" do
    body = [
      { response: "Hello" }.to_json,
      { response: " World" }.to_json,
      { response: "", done: true }.to_json
    ].join("\n")

    result = @provider.send(:extract_text, body)
    assert_equal "Hello World", result
  end

  test "extract_text removes think tags" do
    body = [
      { response: "<think>thinking</think>actual text" }.to_json
    ].join("\n")

    result = @provider.send(:extract_text, body)
    assert_equal "actual text", result
  end

  test "extract_text skips invalid JSON lines" do
    body = "not json\n#{({ response: "ok" }).to_json}\n"
    result = @provider.send(:extract_text, body)
    assert_equal "ok", result
  end
end
