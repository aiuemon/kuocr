require "test_helper"
require "ostruct"

class UserTest < ActiveSupport::TestCase
  test "valid user" do
    user = users(:user)
    assert user.valid?
  end

  test "admin user has admin flag" do
    admin = users(:admin)
    assert admin.admin?
  end

  test "normal user is not admin" do
    user = users(:user)
    assert_not user.admin?
  end

  test "user has many images" do
    user = users(:user)
    assert_respond_to user, :images
  end

  test "user has many image_groups" do
    user = users(:user)
    assert_respond_to user, :image_groups
  end

  test "from_omniauth creates user if not exists" do
    auth = OpenStruct.new(
      info: OpenStruct.new(email: "new_oauth_user@example.com")
    )

    assert_difference "User.count", 1 do
      User.from_omniauth(auth)
    end
  end

  test "from_omniauth returns existing user if exists" do
    existing_user = users(:user)
    auth = OpenStruct.new(
      info: OpenStruct.new(email: existing_user.email)
    )

    assert_no_difference "User.count" do
      user = User.from_omniauth(auth)
      assert_equal existing_user.id, user.id
    end
  end

  test "priority defaults to 3" do
    user = users(:user)
    assert_equal 3, user.priority
  end

  test "priority_manually_set defaults to false" do
    user = users(:user)
    assert_not user.priority_manually_set?
  end

  test "priority must be between 1 and 5" do
    user = users(:user)
    user.priority = 0
    assert_not user.valid?

    user.priority = 6
    assert_not user.valid?

    (1..5).each do |p|
      user.priority = p
      assert user.valid?, "priority #{p} should be valid"
    end
  end

  test "from_omniauth sets priority from SAML affiliations" do
    Setting.affiliation_priority_map = { "faculty" => 1, "staff" => 2 }
    auth = OpenStruct.new(
      provider: "saml_test",
      info: OpenStruct.new(email: "saml_new@example.com"),
      extra: OpenStruct.new(raw_info: { "eduPersonAffiliation" => [ "faculty" ] })
    )

    user = User.from_omniauth(auth)
    assert_equal 1, user.priority
  end

  test "from_omniauth picks highest priority (minimum value) when multiple affiliations match" do
    Setting.affiliation_priority_map = { "faculty" => 1, "member" => 3 }
    auth = OpenStruct.new(
      provider: "saml_test",
      info: OpenStruct.new(email: "saml_multi@example.com"),
      extra: OpenStruct.new(raw_info: { "eduPersonAffiliation" => [ "member", "faculty" ] })
    )

    user = User.from_omniauth(auth)
    assert_equal 1, user.priority
  end

  test "from_omniauth defaults to priority 3 when affiliation not in map" do
    Setting.affiliation_priority_map = { "faculty" => 1 }
    auth = OpenStruct.new(
      provider: "saml_test",
      info: OpenStruct.new(email: "saml_unknown@example.com"),
      extra: OpenStruct.new(raw_info: { "eduPersonAffiliation" => [ "unknown_role" ] })
    )

    user = User.from_omniauth(auth)
    assert_equal 3, user.priority
  end

  test "from_omniauth defaults to priority 3 when eduPersonAffiliation is blank" do
    Setting.affiliation_priority_map = { "faculty" => 1 }
    auth = OpenStruct.new(
      provider: "saml_test",
      info: OpenStruct.new(email: "saml_noaffil@example.com"),
      extra: OpenStruct.new(raw_info: {})
    )

    user = User.from_omniauth(auth)
    assert_equal 3, user.priority
  end

  test "from_omniauth does not set priority from OIDC (defaults to 3)" do
    Setting.affiliation_priority_map = { "faculty" => 1 }
    auth = OpenStruct.new(
      provider: "oidc_test",
      info: OpenStruct.new(email: "oidc_new@example.com"),
      extra: OpenStruct.new(raw_info: { "eduPersonAffiliation" => [ "faculty" ] })
    )

    user = User.from_omniauth(auth)
    assert_equal 3, user.priority
  end

  test "from_omniauth does not update priority for existing users" do
    existing_user = users(:user)
    existing_user.update!(priority: 2)
    Setting.affiliation_priority_map = { "faculty" => 1 }
    auth = OpenStruct.new(
      provider: "saml_test",
      info: OpenStruct.new(email: existing_user.email),
      extra: OpenStruct.new(raw_info: { "eduPersonAffiliation" => [ "faculty" ] })
    )

    User.from_omniauth(auth)
    existing_user.reload
    assert_equal 2, existing_user.priority
  end

  test "storage_usage_bytes returns total size of uploaded images" do
    user = users(:user)
    assert_respond_to user, :storage_usage_bytes
    assert_kind_of Numeric, user.storage_usage_bytes
  end

  test "storage_usage_mb returns usage in megabytes" do
    user = users(:user)
    assert_respond_to user, :storage_usage_mb
    assert_kind_of Numeric, user.storage_usage_mb
  end

  test "quota_exceeded? returns false when under limit" do
    user = users(:user)
    Setting.max_storage_per_user_mb = 1024
    assert_not user.quota_exceeded?
  end

  test "available_storage_bytes returns remaining capacity" do
    user = users(:user)
    Setting.max_storage_per_user_mb = 1024
    assert_kind_of Numeric, user.available_storage_bytes
    assert user.available_storage_bytes >= 0
  end

  test "available_storage_mb returns remaining capacity in mb" do
    user = users(:user)
    Setting.max_storage_per_user_mb = 1024
    assert_kind_of Numeric, user.available_storage_mb
    assert user.available_storage_mb >= 0
  end

  test "invalidate_all_sessions! sets sessions_invalidated_at" do
    user = users(:user)
    assert_nil user.sessions_invalidated_at

    user.invalidate_all_sessions!
    assert_not_nil user.sessions_invalidated_at
  end

  test "session_valid? returns true when sessions_invalidated_at is nil" do
    user = users(:user)
    user.sessions_invalidated_at = nil
    assert user.session_valid?(Time.current.to_i)
  end

  test "session_valid? returns false when signed_in_at is nil and sessions_invalidated_at is set" do
    user = users(:user)
    user.sessions_invalidated_at = Time.current
    assert_not user.session_valid?(nil)
  end

  test "session_valid? returns true when signed_in after invalidation" do
    user = users(:user)
    user.sessions_invalidated_at = 1.hour.ago
    signed_in_at = Time.current.to_i
    assert user.session_valid?(signed_in_at)
  end

  test "session_valid? returns false when signed_in before invalidation" do
    user = users(:user)
    signed_in_at = 2.hours.ago.to_i
    user.sessions_invalidated_at = 1.hour.ago
    assert_not user.session_valid?(signed_in_at)
  end
end
