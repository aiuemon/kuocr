class OcrProcessJob < ApplicationJob
  queue_as :priority_3

  retry_on OcrApiClient::TimeoutError, wait: 30.seconds, attempts: 3
  retry_on OcrApiClient::RequestError, wait: 1.minute, attempts: 2
  discard_on OcrApiClient::ConfigurationError
  discard_on PdfProcessingService::PageLimitExceededError

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
