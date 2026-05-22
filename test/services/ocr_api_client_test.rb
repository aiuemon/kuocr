require "test_helper"

class OcrApiClientTest < ActiveSupport::TestCase
  setup do
    Setting.ocr_endpoint = "https://ocr.example.com/api/generate"
    Setting.ocr_model = "llava:latest"
    Setting.ocr_provider = "ollama"
    Setting.ocr_skip_ssl_verify = false
  end

  test "configured? returns false when endpoint is blank" do
    Setting.ocr_endpoint = ""
    assert_not OcrApiClient.configured?
  end

  test "configured? returns false when model is blank" do
    Setting.ocr_model = ""
    assert_not OcrApiClient.configured?
  end

  test "configured? returns true when endpoint and model are set" do
    assert OcrApiClient.configured?
  end

  test "raises ConfigurationError when endpoint is blank" do
    Setting.ocr_endpoint = ""
    assert_raises(OcrApiClient::ConfigurationError) { OcrApiClient.new }
  end

  test "uses OllamaProvider when provider is ollama" do
    client = OcrApiClient.new
    assert_instance_of OcrApi::OllamaProvider, client.send(:build_provider)
  end

  test "uses OpenAiCompatibleProvider when provider is openai_compatible" do
    Setting.ocr_provider = "openai_compatible"
    client = OcrApiClient.new
    assert_instance_of OcrApi::OpenAiCompatibleProvider, client.send(:build_provider)
  end

  test "uses OllamaProvider as default for unknown provider" do
    Setting.ocr_provider = "unknown"
    client = OcrApiClient.new
    assert_instance_of OcrApi::OllamaProvider, client.send(:build_provider)
  end
end
