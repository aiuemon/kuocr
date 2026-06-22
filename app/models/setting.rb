class Setting < RailsSettings::Base
  cache_prefix { "v1" }

  # === 定数 ===
  DEFAULT_OCR_TIMEOUT = 300

  DEFAULT_OCR_OPTIONS = {
    "temperature" => 0.4,
    "num_predict" => -1,
    "num_ctx" => 33276,
    "num_keep" => 0,
    "repeat_penalty" => 1.2
  }.freeze

  DEFAULT_MAX_STORAGE_MB = 1024
  DEFAULT_AUTO_PURGE_DAYS = 7
  DEFAULT_PDF_MAX_PAGES = 20

  DEFAULT_TIMEZONE = "Asia/Tokyo".freeze

  DEFAULT_NOTIFICATION_SUBJECT = "[kuocr] 文字起こしが完了しました".freeze
  DEFAULT_NOTIFICATION_BODY = <<~BODY.freeze
    {{user_name}} 様

    アップロードされた画像の文字起こし処理が完了しました。

    ファイル名: {{image_name}}
    処理時間: {{ocr_duration}} 秒

    以下のリンクから結果を確認できます:
    {{image_url}}

    ---
    このメールは kuocr から自動送信されています。
  BODY

  # === 認証設定 ===
  field :local_auth_enabled, type: :boolean, default: true
  field :local_auth_show_on_login, type: :boolean, default: true
  field :self_signup_enabled, type: :boolean, default: false
  field :passkey_enabled, type: :boolean, default: false
  field :session_timeout_hours, type: :integer, default: 24
  field :session_timeout_local_hours, type: :integer, default: nil
  field :session_timeout_saml_hours, type: :integer, default: nil
  field :session_timeout_oidc_hours, type: :integer, default: nil
  field :session_timeout_passkey_hours, type: :integer, default: nil

  # === OCR設定 ===
  field :ocr_provider, type: :string, default: "ollama"
  field :ocr_endpoint, type: :string, default: ""
  field :ocr_api_key, type: :string, default: ""
  field :ocr_timeout, type: :integer, default: 300
  field :ocr_model, type: :string, default: ""
  field :ocr_options, type: :hash, default: {}
  field :ocr_skip_ssl_verify, type: :boolean, default: false

  # === クォータ設定 ===
  field :max_storage_per_user_mb, type: :integer, default: 1024

  # === 保持設定 ===
  field :auto_purge_enabled, type: :boolean, default: false
  field :auto_purge_days, type: :integer, default: 7

  # === PDF設定 ===
  field :pdf_max_pages, type: :integer, default: 20

  # === メール通知設定 ===
  field :notification_email_enabled, type: :boolean, default: false
  field :notification_email_subject, type: :string, default: ""
  field :notification_email_body, type: :string, default: ""

  # === SMTP設定 ===
  field :smtp_enabled, type: :boolean, default: false
  field :smtp_address, type: :string, default: ""
  field :smtp_port, type: :integer, default: 587
  field :smtp_authentication, type: :string, default: "plain"
  field :smtp_user_name, type: :string, default: ""
  field :smtp_password, type: :string, default: ""
  field :smtp_enable_starttls, type: :boolean, default: true
  field :smtp_openssl_verify_none, type: :boolean, default: false
  field :smtp_from_address, type: :string, default: ""

  # === タイムゾーン設定 ===
  field :timezone, type: :string, default: "Asia/Tokyo"

  # === SAML SP 設定 ===
  field :saml_sp_entity_id, type: :string, default: ""

  # === 優先度設定 ===
  field :affiliation_priority_map, type: :hash, default: {}

  # === 互換性メソッド ===
  class << self
    # 認証設定
    def local_auth_enabled?
      local_auth_enabled
    end

    def local_auth_show_on_login?
      local_auth_show_on_login
    end

    def self_signup_enabled?
      self_signup_enabled
    end

    def passkey_enabled?
      passkey_enabled
    end

    def effective_session_timeout
      hours = session_timeout_hours
      hours.present? && hours > 0 ? hours.hours : 24.hours
    end

    def timeout_for_auth_method(auth_method)
      hours = case auth_method&.to_s
      when "local"
        session_timeout_local_hours
      when "saml"
        session_timeout_saml_hours
      when "oidc"
        session_timeout_oidc_hours
      when "passkey"
        session_timeout_passkey_hours
      end

      if hours.present? && hours > 0
        hours.hours
      else
        effective_session_timeout
      end
    end

    # OCR設定
    def ocr_configured?
      ocr_endpoint.present? && ocr_model.present?
    end

    def effective_ocr_timeout
      timeout = ocr_timeout
      timeout.present? && timeout > 0 ? timeout : DEFAULT_OCR_TIMEOUT
    end

    def effective_ocr_options
      ocr_options.present? ? ocr_options : DEFAULT_OCR_OPTIONS
    end

    # クォータ設定
    def max_storage_mb
      mb = max_storage_per_user_mb
      mb.present? && mb > 0 ? mb : DEFAULT_MAX_STORAGE_MB
    end

    def max_storage_bytes
      max_storage_mb.megabytes
    end

    # 保持設定
    def auto_purge_enabled?
      auto_purge_enabled
    end

    def effective_auto_purge_days
      days = auto_purge_days
      days.present? && days > 0 ? days : DEFAULT_AUTO_PURGE_DAYS
    end

    # PDF設定
    def effective_pdf_max_pages
      pages = pdf_max_pages
      pages.present? && pages > 0 ? pages : DEFAULT_PDF_MAX_PAGES
    end

    # メール通知設定
    def notification_email_enabled?
      notification_email_enabled
    end

    def effective_notification_subject
      notification_email_subject.presence || DEFAULT_NOTIFICATION_SUBJECT
    end

    def effective_notification_body
      notification_email_body.presence || DEFAULT_NOTIFICATION_BODY
    end

    # SMTP設定
    def smtp_enabled?
      smtp_enabled
    end

    def smtp_configured?
      smtp_enabled && smtp_address.present?
    end

    def smtp_settings
      return {} unless smtp_configured?

      settings = {
        address: smtp_address,
        port: smtp_port,
        enable_starttls_auto: smtp_enable_starttls
      }

      if smtp_authentication.present? && smtp_authentication != "none"
        settings[:authentication] = smtp_authentication.to_sym
        settings[:user_name] = smtp_user_name if smtp_user_name.present?
        settings[:password] = smtp_password if smtp_password.present?
      end

      if smtp_openssl_verify_none
        settings[:openssl_verify_mode] = OpenSSL::SSL::VERIFY_NONE
      end

      settings
    end

    # タイムゾーン設定
    def effective_timezone
      tz = timezone
      tz.present? ? tz : DEFAULT_TIMEZONE
    end

    # SAML SP 設定
    def effective_saml_sp_entity_id(fallback = nil)
      saml_sp_entity_id.presence || fallback || "kuocr"
    end

    # 優先度設定
    def priority_for_affiliations(affiliations)
      return 3 if affiliations.blank?

      map = affiliation_priority_map
      return 3 if map.blank?

      priorities = Array(affiliations).filter_map { |a| map[a.to_s]&.to_i }
      priorities.select { |p| (1..5).include?(p) }.min || 3
    end
  end
end
