class OcrProcessJob < ApplicationJob
  queue_as :priority_3

  # to/duration は limits_concurrency 呼び出し時に一度だけ評価されるため、
  # 管理画面の設定を反映するには concurrency_limit/concurrency_duration を
  # 下で上書きし、実行のたびに Setting から動的に読み直す。
  limits_concurrency key: "ocr_process"

  retry_on OcrApiClient::TimeoutError, wait: 30.seconds, attempts: 3
  retry_on OcrApiClient::RequestError, wait: 1.minute, attempts: 2
  discard_on OcrApiClient::ConfigurationError
  discard_on PdfProcessingService::PageLimitExceededError

  def self.concurrency_limit
    Setting.effective_ocr_job_concurrency
  end

  def self.concurrency_duration
    (Setting.effective_ocr_timeout * Setting.effective_pdf_max_pages).seconds + 5.minutes
  end

  def perform(image_id)
    image = Image.find_by(id: image_id)
    return unless processable?(image)

    strategy = select_strategy(image)
    strategy.process
  end

  private

  def processable?(image)
    image && (image.pending? || image.queued?) && image.file.attached?
  end

  def select_strategy(image)
    if pdf_file?(image)
      OcrProcessing::PdfStrategy.new(image)
    else
      OcrProcessing::ImageStrategy.new(image)
    end
  end

  def pdf_file?(image)
    image.file.content_type == "application/pdf"
  end
end
