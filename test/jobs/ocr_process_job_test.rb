require "test_helper"

class OcrProcessJobTest < ActiveJob::TestCase
  test "skips non-existent image" do
    assert_nothing_raised do
      OcrProcessJob.perform_now(999999)
    end
  end

  test "skips non-pending image" do
    image = images(:completed_image)
    original_status = image.status

    OcrProcessJob.perform_now(image.id)

    image.reload
    assert_equal original_status, image.status
  end

  test "skips image without file" do
    image = images(:pending_image)
    # Fixture image doesn't have attached file
    assert_not image.file.attached?

    OcrProcessJob.perform_now(image.id)

    image.reload
    assert_equal "pending", image.status
  end

  test "job default queue is priority_3" do
    assert_equal "priority_3", OcrProcessJob.new.queue_name
  end

  test "job class exists and inherits from ApplicationJob" do
    assert OcrProcessJob < ApplicationJob
  end

  test "concurrency_limit reflects the current setting" do
    Setting.ocr_job_concurrency = 5
    assert_equal 5, OcrProcessJob.concurrency_limit

    Setting.ocr_job_concurrency = 2
    assert_equal 2, OcrProcessJob.concurrency_limit
  end

  test "concurrency_duration covers the worst-case job runtime" do
    Setting.ocr_timeout = 300
    Setting.pdf_max_pages = 20

    assert_equal 300 * 20 + 5.minutes, OcrProcessJob.concurrency_duration
  end
end
