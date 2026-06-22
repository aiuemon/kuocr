require "test_helper"

class ImageTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  test "valid statuses" do
    assert_equal %w[pending queued processing completed failed], Image::STATUSES
  end

  test "pending? returns true for pending status" do
    image = images(:pending_image)
    assert image.pending?
    assert_not image.queued?
    assert_not image.processing?
    assert_not image.completed?
    assert_not image.failed?
  end

  test "queued? returns true for queued status" do
    image = images(:pending_image)
    image.status = "queued"
    assert image.queued?
    assert_not image.pending?
    assert_not image.processing?
    assert_not image.completed?
    assert_not image.failed?
  end

  test "processing? returns true for processing status" do
    image = images(:processing_image)
    assert image.processing?
    assert_not image.pending?
    assert_not image.queued?
    assert_not image.completed?
    assert_not image.failed?
  end

  test "completed? returns true for completed status" do
    image = images(:completed_image)
    assert image.completed?
    assert_not image.pending?
    assert_not image.queued?
    assert_not image.processing?
    assert_not image.failed?
  end

  test "failed? returns true for failed status" do
    image = images(:failed_image)
    assert image.failed?
    assert_not image.pending?
    assert_not image.queued?
    assert_not image.processing?
    assert_not image.completed?
  end

  test "by_status scope filters by status" do
    completed_images = Image.by_status("completed")
    completed_images.each do |image|
      assert_equal "completed", image.status
    end
  end

  test "recent scope orders by created_at desc" do
    images = Image.recent
    assert images.first.created_at >= images.last.created_at if images.count > 1
  end

  test "belongs to user" do
    image = images(:completed_image)
    assert_respond_to image, :user
    assert_not_nil image.user
  end

  test "belongs to image_group optionally" do
    image = images(:completed_image)
    assert_respond_to image, :image_group
  end

  test "validates presence of name" do
    image = Image.new(status: "pending")
    assert_not image.valid?
    assert_includes image.errors[:name], "can't be blank"
  end

  test "validates status inclusion" do
    image = Image.new(name: "test.png", status: "invalid_status")
    assert_not image.valid?
    assert_includes image.errors[:status], "is not included in the list"
  end

  # Purge-related tests
  test "purged? returns true when purged_at is present" do
    image = images(:purged_image)
    assert image.purged?
  end

  test "purged? returns false when purged_at is nil" do
    image = images(:completed_image)
    assert_not image.purged?
  end

  test "not_purged scope excludes purged images" do
    not_purged_images = Image.not_purged
    not_purged_images.each do |image|
      assert_nil image.purged_at
    end
  end

  test "purged scope includes only purged images" do
    purged_images = Image.purged
    purged_images.each do |image|
      assert_not_nil image.purged_at
    end
  end

  test "purgeable scope finds old completed images without purged_at" do
    Setting.auto_purge_days = 7

    purgeable_images = Image.purgeable
    purgeable_images.each do |image|
      assert_equal "completed", image.status
      assert_nil image.purged_at
      assert image.created_at < 7.days.ago
    end
  end

  test "purgeable scope excludes already purged images" do
    Setting.auto_purge_days = 7

    purgeable_images = Image.purgeable
    assert_not_includes purgeable_images, images(:purged_image)
  end

  test "purge_file! sets purged_at and clears ocr_result" do
    image = images(:old_completed_image)
    assert_not image.purged?
    assert_not_nil image.ocr_result

    image.purge_file!

    assert image.purged?
    assert_not_nil image.purged_at
    assert_nil image.ocr_result
  end

  test "purge_file! does nothing if already purged" do
    image = images(:purged_image)
    original_purged_at = image.purged_at

    image.purge_file!

    assert_equal original_purged_at, image.purged_at
  end

  # ocr_result_missing? tests
  test "ocr_result_missing? returns true when completed but ocr_result is blank" do
    image = images(:completed_image)
    image.ocr_result = nil
    assert image.ocr_result_missing?

    image.ocr_result = ""
    assert image.ocr_result_missing?
  end

  test "ocr_result_missing? returns false when completed and ocr_result is present" do
    image = images(:completed_image)
    image.ocr_result = "Some OCR result"
    assert_not image.ocr_result_missing?
  end

  test "ocr_result_missing? returns false when not completed" do
    image = images(:pending_image)
    image.ocr_result = nil
    assert_not image.ocr_result_missing?
  end

  test "ocr_result_missing? returns false when purged" do
    image = images(:purged_image)
    assert_not image.ocr_result_missing?
  end

  # retryable? tests
  test "retryable? returns true for failed images" do
    image = images(:failed_image)
    assert image.retryable?
  end

  test "retryable? returns true for pending images" do
    image = images(:pending_image)
    assert image.retryable?
  end

  test "retryable? returns true for queued images" do
    image = images(:pending_image)
    image.status = "queued"
    assert image.retryable?
  end

  test "retryable? returns true for completed images with missing ocr_result" do
    image = images(:completed_image)
    image.ocr_result = nil
    assert image.retryable?
  end

  test "retryable? returns false for completed images with ocr_result" do
    image = images(:completed_image)
    image.ocr_result = "Some result"
    assert_not image.retryable?
  end

  test "retryable? returns false for purged images" do
    image = images(:purged_image)
    assert_not image.retryable?
  end

  test "retryable? returns false for processing images" do
    image = images(:processing_image)
    assert_not image.retryable?
  end

  # effective_ocr_prompt tests
  test "effective_ocr_prompt returns ocr_prompt_text when present" do
    image = images(:completed_image)
    image.ocr_prompt_text = "カスタムプロンプト"
    assert_equal "カスタムプロンプト", image.effective_ocr_prompt
  end

  test "effective_ocr_prompt returns pattern prompt when no ocr_prompt_text" do
    image = images(:completed_image)
    pattern = ocr_prompt_patterns(:default_pattern)
    image.ocr_prompt_pattern = pattern
    image.ocr_prompt_text = nil
    assert_equal pattern.prompt, image.effective_ocr_prompt
  end

  test "effective_ocr_prompt returns default pattern prompt when no pattern set" do
    image = images(:completed_image)
    image.ocr_prompt_pattern = nil
    image.ocr_prompt_text = nil
    default_pattern = OcrPromptPattern.default_or_first
    assert_equal default_pattern.prompt, image.effective_ocr_prompt
  end

  test "effective_ocr_prompt returns nil when no patterns exist" do
    image = images(:completed_image)
    image.ocr_prompt_pattern = nil
    image.ocr_prompt_text = nil
    OcrPromptPattern.delete_all
    assert_nil image.effective_ocr_prompt
  end

  test "enqueue_ocr_processing uses queue matching user priority" do
    Setting.ocr_endpoint = "http://example.com/api"
    Setting.ocr_model = "llava:latest"

    user = users(:user)
    user.update!(priority: 2)
    image = images(:pending_image)
    image.update_column(:user_id, user.id)

    assert_enqueued_with(job: OcrProcessJob, queue: "priority_2") do
      image.send(:enqueue_ocr_processing)
    end
  end
end
