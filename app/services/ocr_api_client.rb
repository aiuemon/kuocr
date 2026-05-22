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

    @provider = build_provider
  end

  # 画像を送信して OCR 結果を取得
  # @param image_data [String] 画像のバイナリデータ
  # @param filename [String] ファイル名（未使用だが互換性のため残す）
  # @param content_type [String] Content-Type（OpenAI 互換プロバイダで使用）
  # @param prompt [String] OCR プロンプト（必須）
  # @return [String] OCR 結果テキスト
  def transcribe(image_data:, filename: nil, content_type: nil, prompt:)
    @provider.transcribe(image_data: image_data, content_type: content_type, prompt: prompt)
  end

  # API の設定が有効かどうかを確認
  def self.configured?
    Setting.ocr_configured?
  end

  private

  def build_provider
    provider_class = case Setting.ocr_provider
    when "openai_compatible"
      OcrApi::OpenAiCompatibleProvider
    else
      OcrApi::OllamaProvider
    end

    provider_class.new(
      endpoint: @endpoint,
      api_key: @api_key,
      timeout: @timeout,
      skip_ssl_verify: @skip_ssl_verify
    )
  end
end
