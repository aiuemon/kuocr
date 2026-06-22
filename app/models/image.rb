class Image < ApplicationRecord
  STATUSES = %w[pending queued processing completed failed].freeze

  belongs_to :user
  belongs_to :image_group, optional: true
  belongs_to :ocr_prompt_pattern, optional: true
  has_one_attached :file

  validates :name, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :file, presence: true, unless: :purged?

  after_create_commit :enqueue_ocr_processing

  scope :by_status, ->(status) { where(status: status) }
  scope :recent, -> { order(created_at: :desc) }
  scope :not_purged, -> { where(purged_at: nil) }
  scope :purged, -> { where.not(purged_at: nil) }
  scope :purgeable, lambda {
    days = Setting.effective_auto_purge_days
    where(status: "completed")
      .where(purged_at: nil)
      .where("created_at < ?", days.days.ago)
  }

  def pending?
    status == "pending"
  end

  def queued?
    status == "queued"
  end

  def processing?
    status == "processing"
  end

  def completed?
    status == "completed"
  end

  def failed?
    status == "failed"
  end

  def purged?
    purged_at.present?
  end

  # ステータスが completed だが OCR 結果が空（不整合状態）
  def ocr_result_missing?
    completed? && ocr_result.blank? && !purged?
  end

  # 再試行が可能かどうか
  def retryable?
    !purged? && (failed? || pending? || queued? || ocr_result_missing?)
  end

  # OCR 処理に使用するプロンプトを取得
  # 優先順位: 1. 保存済みのプロンプトテキスト 2. パターンのプロンプト 3. デフォルトパターン
  def effective_ocr_prompt
    return ocr_prompt_text if ocr_prompt_text.present?
    return ocr_prompt_pattern.prompt if ocr_prompt_pattern.present?

    OcrPromptPattern.default_or_first&.prompt
  end

  # ファイルを削除（論理削除）
  def purge_file!
    return if purged?

    transaction do
      file.purge if file.attached?
      update!(purged_at: Time.current, ocr_result: nil)
    end
  end

  # OCR 処理を再実行
  def retry_ocr!
    return unless retryable?

    update!(status: "pending", ocr_result: nil)
    enqueue_ocr_processing
  end

  private

  def enqueue_ocr_processing
    return unless OcrApiClient.configured?

    OcrProcessJob.set(queue: "priority_#{user.priority}").perform_later(id)
  end
end
