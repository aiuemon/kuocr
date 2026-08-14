require "test_helper"

class OcrCompletionMailerTest < ActionMailer::TestCase
  setup do
    @image = images(:completed_image)
    Rails.cache.clear
  end

  test "completion_notification sends email to user" do
    email = OcrCompletionMailer.completion_notification(@image)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ @image.user.email ], email.to
  end

  test "completion_notification uses effective subject from settings" do
    Setting.notification_email_subject = "カスタム件名: {{image_name}}"

    email = OcrCompletionMailer.completion_notification(@image)

    assert_includes email.subject, @image.name
  end

  test "completion_notification replaces placeholders in body" do
    Setting.notification_email_body = "ファイル: {{image_name}}, 時間: {{ocr_duration}} 秒"

    email = OcrCompletionMailer.completion_notification(@image)

    assert_includes email.body.to_s, @image.name
    assert_includes email.body.to_s, @image.ocr_duration.to_s
  end

  test "completion_notification uses default subject when not set" do
    Setting.notification_email_subject = ""

    email = OcrCompletionMailer.completion_notification(@image)

    assert_equal Setting::DEFAULT_NOTIFICATION_SUBJECT, email.subject
  end

  test "completion_notification applies configured smtp settings" do
    Setting.smtp_enabled = true
    Setting.smtp_address = "smtp.example.com"
    Setting.smtp_port = 587
    Setting.smtp_authentication = "plain"
    Setting.smtp_user_name = "user@example.com"
    Setting.smtp_password = "secret"
    Setting.smtp_enable_starttls = true

    email = OcrCompletionMailer.completion_notification(@image)

    assert_equal "smtp.example.com", email.delivery_method.settings[:address]
    assert_equal 587, email.delivery_method.settings[:port]
    assert_equal :plain, email.delivery_method.settings[:authentication]
    assert_equal "user@example.com", email.delivery_method.settings[:user_name]
    assert_equal "secret", email.delivery_method.settings[:password]
    assert_equal true, email.delivery_method.settings[:enable_starttls_auto]
  end

  test "completion_notification does not send when user has no email" do
    @image.user.email = nil

    assert_no_emails do
      OcrCompletionMailer.completion_notification(@image).deliver_now
    end
  end
end
