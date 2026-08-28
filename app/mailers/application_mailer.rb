class ApplicationMailer < ActionMailer::Base
  layout "mailer"

  default from: -> { Setting.smtp_from_address.presence || "noreply@example.com" }

  after_action :configure_smtp_settings

  private

  def configure_smtp_settings
    return unless Setting.smtp_configured?

    mail.delivery_method.settings.merge!(Setting.smtp_settings)
  end
end
