require "test_helper"

class OcrApi::OpenAiCompatibleProviderTest < ActiveSupport::TestCase
  setup do
    Setting.ocr_endpoint = "https://api.openai.com/v1/chat/completions"
    Setting.ocr_model = "gpt-4o"
    Setting.ocr_skip_ssl_verify = false
    Setting.ocr_options = { "temperature" => 0.4 }
    @provider = OcrApi::OpenAiCompatibleProvider.new(
      endpoint: Setting.ocr_endpoint,
      api_key: "sk-test",
      timeout: 30,
      skip_ssl_verify: false
    )
    @image_data = "fake_image_bytes"
    @prompt = "文字を起こしてください"
  end

  test "build_request sets OpenAI chat completions format payload" do
    uri = URI.parse(Setting.ocr_endpoint)
    request = @provider.send(:build_request, uri, @image_data, "image/jpeg", @prompt)

    payload = JSON.parse(request.body, symbolize_names: true)
    assert_equal "gpt-4o", payload[:model]
    assert payload[:stream]
    messages = payload[:messages]
    assert_equal 1, messages.length
    assert_equal "user", messages[0][:role]
    content = messages[0][:content]
    assert_equal 2, content.length
    assert_equal "image_url", content[0][:type]
    assert content[0][:image_url][:url].start_with?("data:image/jpeg;base64,")
    assert_equal "text", content[1][:type]
    assert_equal @prompt, content[1][:text]
  end

  test "build_request uses provided content_type in data URI" do
    uri = URI.parse(Setting.ocr_endpoint)
    request = @provider.send(:build_request, uri, @image_data, "image/png", @prompt)

    payload = JSON.parse(request.body, symbolize_names: true)
    assert payload[:messages][0][:content][0][:image_url][:url].start_with?("data:image/png;base64,")
  end

  test "build_request defaults content_type to image/jpeg when nil" do
    uri = URI.parse(Setting.ocr_endpoint)
    request = @provider.send(:build_request, uri, @image_data, nil, @prompt)

    payload = JSON.parse(request.body, symbolize_names: true)
    assert payload[:messages][0][:content][0][:image_url][:url].start_with?("data:image/jpeg;base64,")
  end

  test "build_request includes allowed options as top-level keys" do
    uri = URI.parse(Setting.ocr_endpoint)
    request = @provider.send(:build_request, uri, @image_data, "image/jpeg", @prompt)

    payload = JSON.parse(request.body, symbolize_names: true)
    assert_equal 0.4, payload[:temperature]
  end

  test "build_request excludes Ollama-specific options" do
    Setting.ocr_options = { "temperature" => 0.5, "num_predict" => -1, "num_ctx" => 33276 }
    uri = URI.parse(Setting.ocr_endpoint)
    request = @provider.send(:build_request, uri, @image_data, "image/jpeg", @prompt)

    payload = JSON.parse(request.body, symbolize_names: true)
    assert_equal 0.5, payload[:temperature]
    assert_nil payload[:num_predict]
    assert_nil payload[:num_ctx]
  end

  test "extract_text parses SSE streaming response" do
    body = [
      'data: {"choices":[{"delta":{"role":"assistant","content":""},"finish_reason":null}]}',
      'data: {"choices":[{"delta":{"content":"Hello"},"finish_reason":null}]}',
      'data: {"choices":[{"delta":{"content":" World"},"finish_reason":null}]}',
      "data: [DONE]"
    ].join("\n")

    result = @provider.send(:extract_text, body)
    assert_equal "Hello World", result
  end

  test "extract_text removes think tags" do
    body = 'data: {"choices":[{"delta":{"content":"<think>thinking</think>actual text"},"finish_reason":null}]}'
    result = @provider.send(:extract_text, body)
    assert_equal "actual text", result
  end

  test "extract_text skips non-data lines and invalid JSON" do
    body = "event: message\nnot json data\ndata: [DONE]"
    result = @provider.send(:extract_text, body)
    assert_equal "", result
  end
end
