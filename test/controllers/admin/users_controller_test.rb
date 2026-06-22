require "test_helper"

module Admin
  class UsersControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin = users(:admin)
      @user = users(:user)
    end

    test "requires authentication" do
      get admin_users_path
      assert_redirected_to new_user_session_path
    end

    test "requires admin role" do
      sign_in @user
      get admin_users_path
      assert_redirected_to root_path
      assert_equal "管理者権限が必要です。", flash[:alert]
    end

    test "index returns success for admin" do
      sign_in @admin
      get admin_users_path
      assert_response :success
    end

    test "index supports sorting" do
      sign_in @admin
      get admin_users_path(sort: "name", dir: "asc")
      assert_response :success
    end

    test "toggle_admin grants admin to user" do
      sign_in @admin
      assert_not @user.admin?

      patch toggle_admin_admin_user_path(@user)
      assert_redirected_to admin_users_path

      @user.reload
      assert @user.admin?
    end

    test "toggle_admin revokes admin from admin user" do
      other_admin = User.create!(
        email: "other_admin@example.com",
        password: "password123",
        admin: true
      )
      sign_in @admin

      patch toggle_admin_admin_user_path(other_admin)
      assert_redirected_to admin_users_path

      other_admin.reload
      assert_not other_admin.admin?
    end

    test "toggle_admin cannot change own admin status" do
      sign_in @admin

      patch toggle_admin_admin_user_path(@admin)
      assert_redirected_to admin_users_path
      assert_equal "自分自身の管理者権限は変更できません。", flash[:alert]

      @admin.reload
      assert @admin.admin?
    end

    test "invalidate_sessions invalidates user sessions" do
      sign_in @admin
      assert_nil @user.sessions_invalidated_at

      patch invalidate_sessions_admin_user_path(@user)
      assert_redirected_to admin_users_path
      assert_match /セッションを無効化しました/, flash[:notice]

      @user.reload
      assert_not_nil @user.sessions_invalidated_at
    end

    test "invalidate_sessions cannot invalidate own sessions" do
      sign_in @admin

      patch invalidate_sessions_admin_user_path(@admin)
      assert_redirected_to admin_users_path
      assert_equal "自分自身のセッションは無効化できません。", flash[:alert]

      @admin.reload
      assert_nil @admin.sessions_invalidated_at
    end

    test "invalidate_sessions requires admin role" do
      sign_in @user

      patch invalidate_sessions_admin_user_path(@admin)
      assert_redirected_to root_path
    end

    test "update_priority changes user priority and sets priority_manually_set" do
      sign_in @admin
      assert_equal 3, @user.priority
      assert_not @user.priority_manually_set?

      patch update_priority_admin_user_path(@user), params: { priority: 1 }
      assert_redirected_to admin_users_path
      assert_match /優先度を 1 に変更しました/, flash[:notice]

      @user.reload
      assert_equal 1, @user.priority
      assert @user.priority_manually_set?
    end

    test "update_priority rejects invalid priority" do
      sign_in @admin
      patch update_priority_admin_user_path(@user), params: { priority: 6 }
      assert_redirected_to admin_users_path
      assert_match /失敗しました/, flash[:alert]
    end

    test "update_priority cannot change own priority" do
      sign_in @admin
      original_priority = @admin.priority

      patch update_priority_admin_user_path(@admin), params: { priority: 1 }
      assert_redirected_to admin_users_path
      assert_equal "自分自身の優先度は変更できません。", flash[:alert]

      @admin.reload
      assert_equal original_priority, @admin.priority
    end

    test "update_priority requires admin role" do
      sign_in @user

      patch update_priority_admin_user_path(@admin), params: { priority: 1 }
      assert_redirected_to root_path
    end
  end
end
