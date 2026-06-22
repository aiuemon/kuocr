require "test_helper"

module Forms
  class AffilPrioritySettingsFormTest < ActiveSupport::TestCase
    setup do
      Rails.cache.clear
      Setting.affiliation_priority_map = {}
    end

    test "loads mappings from settings on initialize" do
      Setting.affiliation_priority_map = { "faculty" => 1, "staff" => 2 }
      form = AffilPrioritySettingsForm.new
      assert_equal 2, form.mappings.length
    end

    test "save stores mappings to setting" do
      form = AffilPrioritySettingsForm.new(
        mappings: [
          { affiliation: "faculty", priority: "1" },
          { affiliation: "staff", priority: "2" }
        ]
      )
      assert form.save
      assert_equal({ "faculty" => 1, "staff" => 2 }, Setting.affiliation_priority_map)
    end

    test "save skips blank affiliation rows" do
      form = AffilPrioritySettingsForm.new(
        mappings: [
          { affiliation: "", priority: "1" },
          { affiliation: "faculty", priority: "2" }
        ]
      )
      assert form.save
      assert_equal({ "faculty" => 2 }, Setting.affiliation_priority_map)
    end

    test "save strips whitespace from affiliation" do
      form = AffilPrioritySettingsForm.new(
        mappings: [ { affiliation: "  faculty  ", priority: "1" } ]
      )
      assert form.save
      assert Setting.affiliation_priority_map.key?("faculty")
    end

    test "invalid when priority out of range" do
      form = AffilPrioritySettingsForm.new(
        mappings: [ { affiliation: "faculty", priority: "6" } ]
      )
      assert_not form.valid?
      assert form.errors[:mappings].present?
    end

    test "save with empty mappings clears the setting" do
      Setting.affiliation_priority_map = { "faculty" => 1 }
      form = AffilPrioritySettingsForm.new(mappings: [])
      assert form.save
      assert_equal({}, Setting.affiliation_priority_map)
    end

    test "save works when mappings is a hash with numeric string keys (from params)" do
      form = AffilPrioritySettingsForm.new(
        mappings: {
          "0" => { "affiliation" => "faculty", "priority" => "2" },
          "1" => { "affiliation" => "staff", "priority" => "2" },
          "2" => { "affiliation" => "student", "priority" => "4" }
        }
      )
      assert form.save
      assert_equal({ "faculty" => 2, "staff" => 2, "student" => 4 }, Setting.affiliation_priority_map)
    end
  end
end
