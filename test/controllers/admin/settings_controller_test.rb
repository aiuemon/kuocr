require "test_helper"

module Admin
  class SettingsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin = users(:admin)
      @user = users(:user)
      Rails.cache.clear
    end

    test "requires authentication" do
      get admin_settings_path
      assert_redirected_to new_user_session_path
    end

    test "requires admin role" do
      sign_in @user
      get admin_settings_path
      assert_redirected_to root_path
      assert_equal "管理者権限が必要です。", flash[:alert]
    end

    test "show returns success for admin" do
      sign_in @admin
      get admin_settings_path
      assert_response :success
    end

    test "show displays all settings sections" do
      sign_in @admin
      get admin_settings_path
      assert_response :success
      assert_select "#collapseAuth"
      assert_select "#collapseOcr"
      assert_select "#collapseSmtp"
      assert_select "#collapseUserFiles"
      assert_select "#collapseNotification"
      assert_select "#collapseTimezone"
    end

    # Auth settings tests
    test "update_auth enables local auth" do
      sign_in @admin
      Setting.local_auth_enabled = false

      patch update_auth_admin_settings_path, params: {
        auth_settings: { local_auth_enabled: true }
      }

      assert_redirected_to admin_settings_path(anchor: "collapseAuth")
      assert Setting.local_auth_enabled?
    end

    test "update_auth changes self signup setting" do
      sign_in @admin
      Setting.self_signup_enabled = false

      patch update_auth_admin_settings_path, params: {
        auth_settings: { self_signup_enabled: true }
      }

      assert_redirected_to admin_settings_path(anchor: "collapseAuth")
      assert Setting.self_signup_enabled?
    end

    # OCR settings tests
    test "update_ocr changes endpoint" do
      sign_in @admin

      patch update_ocr_admin_settings_path, params: {
        ocr_settings: { endpoint: "http://new.example.com/api" }
      }

      assert_redirected_to admin_settings_path(anchor: "collapseOcr")
      assert_equal "http://new.example.com/api", Setting.ocr_endpoint
    end

    test "update_ocr validates json options" do
      sign_in @admin

      patch update_ocr_admin_settings_path, params: {
        ocr_settings: { options: "invalid json" }
      }

      assert_response :unprocessable_entity
    end

    # Quota settings tests
    test "update_quota changes max storage" do
      sign_in @admin

      patch update_quota_admin_settings_path, params: {
        quota_settings: { max_storage_per_user_mb: 500 }
      }

      assert_redirected_to admin_settings_path(anchor: "collapseUserFiles")
      assert_equal 500, Setting.max_storage_per_user_mb
    end

    # Retention settings tests
    test "update_retention enables auto purge" do
      sign_in @admin
      Setting.auto_purge_enabled = false

      patch update_retention_admin_settings_path, params: {
        retention_settings: { auto_purge_enabled: true, auto_purge_days: 14 }
      }

      assert_redirected_to admin_settings_path(anchor: "collapseUserFiles")
      assert Setting.auto_purge_enabled?
      assert_equal 14, Setting.auto_purge_days
    end

    test "update_retention disables auto purge" do
      sign_in @admin
      Setting.auto_purge_enabled = true

      patch update_retention_admin_settings_path, params: {
        retention_settings: { auto_purge_enabled: false }
      }

      assert_redirected_to admin_settings_path(anchor: "collapseUserFiles")
      assert_not Setting.auto_purge_enabled?
    end

    test "update_retention validates auto_purge_days" do
      sign_in @admin

      patch update_retention_admin_settings_path, params: {
        retention_settings: { auto_purge_enabled: true, auto_purge_days: 0 }
      }

      assert_response :unprocessable_entity
    end

    test "update_retention requires admin" do
      sign_in @user

      patch update_retention_admin_settings_path, params: {
        retention_settings: { auto_purge_enabled: true }
      }

      assert_redirected_to root_path
    end

    # Notification settings tests
    test "update_notification enables email notification" do
      sign_in @admin
      Setting.notification_email_enabled = false

      patch update_notification_admin_settings_path, params: {
        notification_settings: {
          enabled: true,
          subject: "テスト件名",
          body: "テスト本文"
        }
      }

      assert_redirected_to admin_settings_path(anchor: "collapseNotification")
      assert Setting.notification_email_enabled?
      assert_equal "テスト件名", Setting.notification_email_subject
      assert_equal "テスト本文", Setting.notification_email_body
    end

    test "update_notification disables email notification" do
      sign_in @admin
      Setting.notification_email_enabled = true

      patch update_notification_admin_settings_path, params: {
        notification_settings: { enabled: false }
      }

      assert_redirected_to admin_settings_path(anchor: "collapseNotification")
      assert_not Setting.notification_email_enabled?
    end

    test "update_notification requires admin" do
      sign_in @user

      patch update_notification_admin_settings_path, params: {
        notification_settings: { enabled: true }
      }

      assert_redirected_to root_path
    end

    # SMTP settings tests
    test "update_smtp enables smtp" do
      sign_in @admin
      Setting.smtp_enabled = false

      patch update_smtp_admin_settings_path, params: {
        smtp_settings: {
          enabled: true,
          address: "smtp.example.com",
          port: 587,
          authentication: "plain",
          user_name: "user@example.com",
          password: "secret",
          enable_starttls: true,
          from_address: "noreply@example.com"
        }
      }

      assert_redirected_to admin_settings_path(anchor: "collapseSmtp")
      assert Setting.smtp_enabled?
      assert_equal "smtp.example.com", Setting.smtp_address
      assert_equal 587, Setting.smtp_port
      assert_equal "plain", Setting.smtp_authentication
      assert_equal "user@example.com", Setting.smtp_user_name
      assert_equal "secret", Setting.smtp_password
      assert Setting.smtp_enable_starttls
      assert_equal "noreply@example.com", Setting.smtp_from_address
    end

    test "update_smtp disables smtp" do
      sign_in @admin
      Setting.smtp_enabled = true

      patch update_smtp_admin_settings_path, params: {
        smtp_settings: { enabled: false }
      }

      assert_redirected_to admin_settings_path(anchor: "collapseSmtp")
      assert_not Setting.smtp_enabled?
    end

    test "update_smtp validates address when enabled" do
      sign_in @admin

      patch update_smtp_admin_settings_path, params: {
        smtp_settings: { enabled: true, address: "" }
      }

      assert_response :unprocessable_entity
    end

    test "update_smtp validates port number" do
      sign_in @admin

      patch update_smtp_admin_settings_path, params: {
        smtp_settings: { enabled: true, address: "smtp.example.com", port: 99999 }
      }

      assert_response :unprocessable_entity
    end

    test "update_smtp requires admin" do
      sign_in @user

      patch update_smtp_admin_settings_path, params: {
        smtp_settings: { enabled: true }
      }

      assert_redirected_to root_path
    end

    # Test email tests
    test "send_test_email sends email successfully" do
      sign_in @admin

      post send_test_email_admin_settings_path, params: {
        to_address: "test@example.com",
        smtp_settings: {
          address: "smtp.example.com",
          port: "587",
          authentication: "plain",
          user_name: "user",
          password: "pass",
          enable_starttls: "true",
          from_address: "noreply@example.com"
        }
      }

      assert_response :success
      json = JSON.parse(response.body)
      assert json["success"]
      assert_equal "テストメールを送信しました", json["message"]
    end

    test "send_test_email requires to_address" do
      sign_in @admin

      post send_test_email_admin_settings_path, params: {
        to_address: "",
        smtp_settings: { address: "smtp.example.com" }
      }

      assert_response :unprocessable_entity
      json = JSON.parse(response.body)
      assert_not json["success"]
      assert_equal "宛先メールアドレスを入力してください", json["error"]
    end

    test "send_test_email requires admin" do
      sign_in @user

      post send_test_email_admin_settings_path, params: {
        to_address: "test@example.com"
      }

      assert_redirected_to root_path
    end

    # PDF settings tests
    test "update_pdf changes max pages and dpi" do
      sign_in @admin

      patch update_pdf_admin_settings_path, params: {
        pdf_settings: { max_pages: 50, dpi: 150 }
      }

      assert_redirected_to admin_settings_path(anchor: "collapseUserFiles")
      assert_equal 50, Setting.pdf_max_pages
      assert_equal 150, Setting.pdf_dpi
    end

    test "update_pdf uses default when blank" do
      sign_in @admin
      Setting.pdf_max_pages = 50
      Setting.pdf_dpi = 200

      patch update_pdf_admin_settings_path, params: {
        pdf_settings: { max_pages: "", dpi: "" }
      }

      assert_redirected_to admin_settings_path(anchor: "collapseUserFiles")
      assert_equal Setting::DEFAULT_PDF_MAX_PAGES, Setting.pdf_max_pages
      assert_equal Setting::DEFAULT_PDF_DPI, Setting.pdf_dpi
    end

    test "update_pdf validates max pages range" do
      sign_in @admin

      patch update_pdf_admin_settings_path, params: {
        pdf_settings: { max_pages: 0 }
      }

      assert_response :unprocessable_entity
    end

    test "update_pdf validates max pages upper limit" do
      sign_in @admin

      patch update_pdf_admin_settings_path, params: {
        pdf_settings: { max_pages: 101 }
      }

      assert_response :unprocessable_entity
    end

    test "update_pdf validates dpi option" do
      sign_in @admin

      patch update_pdf_admin_settings_path, params: {
        pdf_settings: { max_pages: 20, dpi: 72 }
      }

      assert_response :unprocessable_entity
    end

    test "update_pdf requires admin" do
      sign_in @user

      patch update_pdf_admin_settings_path, params: {
        pdf_settings: { max_pages: 50 }
      }

      assert_redirected_to root_path
    end

    # Timezone settings tests
    test "update_timezone changes timezone" do
      sign_in @admin

      patch update_timezone_admin_settings_path, params: {
        timezone_settings: { timezone: "America/New_York" }
      }

      assert_redirected_to admin_settings_path(anchor: "collapseTimezone")
      assert_equal "America/New_York", Setting.timezone
    end

    test "update_timezone validates timezone" do
      sign_in @admin

      patch update_timezone_admin_settings_path, params: {
        timezone_settings: { timezone: "Invalid/Timezone" }
      }

      assert_response :unprocessable_entity
    end

    test "update_timezone requires admin" do
      sign_in @user

      patch update_timezone_admin_settings_path, params: {
        timezone_settings: { timezone: "America/New_York" }
      }

      assert_redirected_to root_path
    end

    # Passkey settings tests
    test "update_passkey enables passkey" do
      sign_in @admin
      Setting.passkey_enabled = false

      patch update_passkey_admin_settings_path, params: {
        passkey_settings: { enabled: true }
      }

      assert_redirected_to admin_settings_path(anchor: "collapseAuth")
      assert Setting.passkey_enabled?
    end

    test "update_passkey disables passkey" do
      sign_in @admin
      Setting.passkey_enabled = true

      patch update_passkey_admin_settings_path, params: {
        passkey_settings: { enabled: false }
      }

      assert_redirected_to admin_settings_path(anchor: "collapseAuth")
      assert_not Setting.passkey_enabled?
    end

    test "update_passkey requires admin" do
      sign_in @user

      patch update_passkey_admin_settings_path, params: {
        passkey_settings: { enabled: true }
      }

      assert_redirected_to root_path
    end
  end
end
