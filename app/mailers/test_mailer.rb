class TestMailer < ApplicationMailer
  skip_after_action :configure_smtp_settings

  def test_email(to:, smtp_settings: {})
    @sent_at = Time.current

    message = mail(
      to: to,
      subject: "[kuocr] SMTP 設定テストメール",
      from: smtp_settings[:from_address].presence || Setting.smtp_from_address.presence || "noreply@example.com"
    )

    # 動的に SMTP 設定を適用（mail を呼んだ後に設定）
    if smtp_settings.present?
      message.delivery_method.settings.merge!(smtp_settings)
    end

    message
  end
end
