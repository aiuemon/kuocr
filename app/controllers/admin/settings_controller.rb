module Admin
  class SettingsController < BaseController
    # 設定タイプごとのメタデータ
    # form_class: フォームクラス
    # message: 成功時のメッセージ
    # anchor: リダイレクト時のアンカー
    # param_key: Strong Parameters のキー
    # permitted: 許可するパラメータ
    SETTING_CONFIGS = {
      auth: {
        form_class: Forms::AuthSettingsForm,
        message: "認証設定を更新しました。",
        anchor: "collapseAuth",
        param_key: :auth_settings,
        permitted: %i[local_auth_enabled local_auth_show_on_login self_signup_enabled session_timeout_hours session_timeout_local_hours session_timeout_saml_hours session_timeout_oidc_hours session_timeout_passkey_hours]
      },
      passkey: {
        form_class: Forms::PasskeySettingsForm,
        message: "パスキー設定を更新しました。",
        anchor: "collapseAuth",
        param_key: :passkey_settings,
        permitted: %i[enabled]
      },
      ocr: {
        form_class: Forms::OcrSettingsForm,
        message: "OCR設定を更新しました。",
        anchor: "collapseOcr",
        param_key: :ocr_settings,
        permitted: %i[provider endpoint api_key timeout model prompt options skip_ssl_verify]
      },
      quota: {
        form_class: Forms::QuotaSettingsForm,
        message: "クォータ設定を更新しました。",
        anchor: "collapseUserFiles",
        param_key: :quota_settings,
        permitted: %i[max_storage_per_user_mb]
      },
      retention: {
        form_class: Forms::RetentionSettingsForm,
        message: "保持設定を更新しました。",
        anchor: "collapseUserFiles",
        param_key: :retention_settings,
        permitted: %i[auto_purge_enabled auto_purge_days]
      },
      pdf: {
        form_class: Forms::PdfSettingsForm,
        message: "PDF設定を更新しました。",
        anchor: "collapseUserFiles",
        param_key: :pdf_settings,
        permitted: %i[max_pages dpi]
      },
      notification: {
        form_class: Forms::NotificationSettingsForm,
        message: "通知メール設定を更新しました。",
        anchor: "collapseNotification",
        param_key: :notification_settings,
        permitted: %i[enabled subject body]
      },
      smtp: {
        form_class: Forms::SmtpSettingsForm,
        message: "送信メールサーバ設定を更新しました。",
        anchor: "collapseSmtp",
        param_key: :smtp_settings,
        permitted: %i[enabled address port authentication user_name password enable_starttls openssl_verify_none from_address]
      },
      timezone: {
        form_class: Forms::TimezoneSettingsForm,
        message: "タイムゾーン設定を更新しました。",
        anchor: "collapseTimezone",
        param_key: :timezone_settings,
        permitted: %i[timezone]
      },
      affil_priority: {
        form_class: Forms::AffilPrioritySettingsForm,
        message: "所属属性・優先度マッピングを更新しました。",
        anchor: "collapseAffilPriority",
        param_key: :affil_priority_settings,
        permitted: { mappings: %i[affiliation priority] }
      }
    }.freeze

    def show
      load_all_forms
    end

    # 各設定タイプの update アクションを動的に定義
    SETTING_CONFIGS.each_key do |setting_type|
      define_method("update_#{setting_type}") do
        update_setting(setting_type)
      end
    end

    def send_test_email
      to_address = params[:to_address]

      if to_address.blank?
        render json: { success: false, error: "宛先メールアドレスを入力してください" }, status: :unprocessable_entity
        return
      end

      smtp_settings = build_smtp_settings_from_params

      begin
        TestMailer.test_email(to: to_address, smtp_settings: smtp_settings).deliver_now
        render json: { success: true, message: "テストメールを送信しました" }
      rescue => e
        render json: { success: false, error: "送信に失敗しました: #{e.message}" }, status: :unprocessable_entity
      end
    end

    private

    def update_setting(setting_type)
      config = SETTING_CONFIGS[setting_type]
      form = config[:form_class].new(setting_params(setting_type))
      instance_variable_set("@#{setting_type}_form", form)

      if form.save
        respond_to do |format|
          format.turbo_stream { render_turbo_flash(setting_type, config[:message], :success) }
          format.html { redirect_to admin_settings_path(anchor: config[:anchor]), notice: config[:message] }
        end
      else
        respond_to do |format|
          format.turbo_stream { render_turbo_flash(setting_type, form.errors.full_messages.join(", "), :error) }
          format.html do
            load_other_forms(setting_type)
            render :show, status: :unprocessable_entity
          end
        end
      end
    end

    def setting_params(setting_type)
      config = SETTING_CONFIGS[setting_type]
      params.require(config[:param_key]).permit(config[:permitted])
    end

    def render_turbo_flash(section, message, type)
      alert_class = type == :success ? "alert-success" : "alert-danger"
      render turbo_stream: turbo_stream.update(
        "flash_#{section}",
        "<div class=\"alert #{alert_class} alert-dismissible fade show\" role=\"alert\">#{ERB::Util.html_escape(message)}<button type=\"button\" class=\"btn-close\" data-bs-dismiss=\"alert\" aria-label=\"Close\"></button></div>"
      )
    end

    def build_smtp_settings_from_params
      smtp_params = params[:smtp_settings] || {}

      settings = {
        address: smtp_params[:address].presence,
        port: smtp_params[:port].to_i,
        enable_starttls_auto: smtp_params[:enable_starttls] == "true" || smtp_params[:enable_starttls] == "1",
        from_address: smtp_params[:from_address].presence
      }

      auth = smtp_params[:authentication].presence
      if auth.present? && auth != "none"
        settings[:authentication] = auth.to_sym
        settings[:user_name] = smtp_params[:user_name].presence
        # パスワードが入力されていればそれを使用、なければ保存済みのパスワードを使用
        settings[:password] = smtp_params[:password].presence || Setting.smtp_password.presence
      end

      # サーバ証明書の検証をスキップ
      if smtp_params[:openssl_verify_none] == "true" || smtp_params[:openssl_verify_none] == "1"
        settings[:openssl_verify_mode] = OpenSSL::SSL::VERIFY_NONE
      end

      settings.compact
    end

    def load_all_forms
      SETTING_CONFIGS.each do |setting_type, config|
        instance_variable_set("@#{setting_type}_form", config[:form_class].new)
      end
    end

    def load_other_forms(exclude_type = nil)
      SETTING_CONFIGS.each do |setting_type, config|
        next if setting_type == exclude_type

        var_name = "@#{setting_type}_form"
        instance_variable_set(var_name, config[:form_class].new) unless instance_variable_get(var_name)
      end
    end
  end
end
