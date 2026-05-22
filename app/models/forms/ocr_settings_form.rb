module Forms
  class OcrSettingsForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    PROVIDERS = [
      [ "Ollama", "ollama" ],
      [ "OpenAI 互換", "openai_compatible" ]
    ].freeze

    attribute :provider, :string, default: "ollama"
    attribute :endpoint, :string
    attribute :api_key, :string
    attribute :timeout, :integer
    attribute :model, :string
    attribute :options, :string
    attribute :skip_ssl_verify, :boolean, default: false

    validates :provider, inclusion: { in: PROVIDERS.map(&:last) }
    validates :timeout, numericality: { greater_than: 0, less_than_or_equal_to: 3600 }, allow_blank: true
    validate :validate_options_json

    def initialize(attributes = {})
      super
      load_from_settings if attributes.empty?
    end

    def save
      return false unless valid?

      Setting.ocr_provider = provider.to_s
      Setting.ocr_endpoint = endpoint.to_s
      Setting.ocr_api_key = api_key.to_s
      Setting.ocr_timeout = timeout.presence || Setting::DEFAULT_OCR_TIMEOUT
      Setting.ocr_model = model.to_s
      Setting.ocr_options = parsed_options
      Setting.ocr_skip_ssl_verify = skip_ssl_verify
      true
    rescue => e
      errors.add(:base, e.message)
      false
    end

    def persisted?
      true
    end

    def to_key
      [ :ocr_settings ]
    end

    def model_name
      ActiveModel::Name.new(self, nil, "OcrSettings")
    end

    def options_for_display
      opts = Setting.ocr_options
      opts.present? ? JSON.pretty_generate(opts) : JSON.pretty_generate(Setting::DEFAULT_OCR_OPTIONS)
    end

    private

    def load_from_settings
      self.provider = Setting.ocr_provider.presence || "ollama"
      self.endpoint = Setting.ocr_endpoint
      self.api_key = Setting.ocr_api_key
      self.timeout = Setting.ocr_timeout
      self.model = Setting.ocr_model
      self.options = options_for_display
      self.skip_ssl_verify = Setting.ocr_skip_ssl_verify
    end

    def parsed_options
      return {} if options.blank?
      JSON.parse(options)
    rescue JSON::ParserError
      {}
    end

    def validate_options_json
      return if options.blank?
      JSON.parse(options)
    rescue JSON::ParserError
      errors.add(:options, "の JSON 形式が不正です")
    end
  end
end
