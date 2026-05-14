require "net/http"
require "uri"
require "json"
require "base64"
require "openssl"

class OcrApiClient
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class RequestError < Error; end
  class TimeoutError < Error; end

  def initialize
    @endpoint = Setting.ocr_endpoint
    @api_key = Setting.ocr_api_key
    @timeout = Setting.effective_ocr_timeout
    @skip_ssl_verify = Setting.ocr_skip_ssl_verify

    raise ConfigurationError, "OCR API endpoint is not configured" if @endpoint.blank?
  end

  # 画像を送信して OCR 結果を取得
  # @param image_data [String] 画像のバイナリデータ
  # @param filename [String] ファイル名（未使用だが互換性のため残す）
  # @param content_type [String] Content-Type（未使用だが互換性のため残す）
  # @param prompt [String] OCR プロンプト（必須）
  # @return [String] OCR 結果テキスト
  def transcribe(image_data:, filename: nil, content_type: nil, prompt:)
    uri = URI.parse(@endpoint)
    http = build_http_client(uri)

    request = build_json_request(uri, image_data, prompt)
    response = execute_request(http, request)

    parse_response(response)
  end

  # API の設定が有効かどうかを確認
  def self.configured?
    Setting.ocr_configured?
  end

  private

  def build_http_client(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE if @skip_ssl_verify
    http.open_timeout = @timeout
    http.read_timeout = @timeout
    http
  end

  def build_json_request(uri, image_data, prompt)
    image_b64 = Base64.strict_encode64(image_data)

    payload = {
      model: Setting.ocr_model,
      prompt: prompt,
      images: [ image_b64 ],
      stream: true,
      options: Setting.effective_ocr_options
    }

    request = Net::HTTP::Post.new(uri.request_uri)
    request["Content-Type"] = "application/json"
    request["Accept"] = "application/json"
    request["Authorization"] = "Bearer #{@api_key}" if @api_key.present?
    request.body = payload.to_json

    request
  end

  def execute_request(http, request)
    http.request(request)
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    raise TimeoutError, "API request timed out: #{e.message}"
  rescue StandardError => e
    raise RequestError, "API request failed: #{e.message}"
  end

  def parse_response(response)
    case response.code.to_i
    when 200..299
      extract_streaming_text(response.body)
    when 401
      raise RequestError, "Authentication failed: Invalid API key"
    when 404
      raise RequestError, "API endpoint not found"
    when 429
      raise RequestError, "Rate limit exceeded"
    when 500..599
      raise RequestError, "API server error: #{response.code} - #{response.body.to_s.truncate(500)}"
    else
      raise RequestError, "Unexpected response: #{response.code} - #{response.body}"
    end
  end

  # ストリーミングレスポンス（NDJSON）からテキストを抽出
  # 各行の response を連結し、<think>...</think> タグを除去
  def extract_streaming_text(body)
    text = ""

    body.each_line do |line|
      line = line.strip
      next if line.empty?

      begin
        data = JSON.parse(line, symbolize_names: true)
        text += data[:response] || data[:text] || data[:content] || ""
      rescue JSON::ParserError
        # 不正な JSON 行はスキップ
        next
      end
    end

    # <think>...</think> タグを除去
    text.gsub(%r{<think>.*?</think>}m, "").strip
  end
end
