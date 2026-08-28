# frozen_string_literal: true

module Forms
  class PdfSettingsForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    DPI_OPTIONS = [
      [ "高速 (96dpi)", 96 ],
      [ "標準 (120dpi)", 120 ],
      [ "高精度 (150dpi)", 150 ],
      [ "最高精度 (200dpi)", 200 ]
    ].freeze

    attribute :max_pages, :integer
    attribute :dpi, :integer

    validates :max_pages,
      numericality: { greater_than: 0, less_than_or_equal_to: 100, message: "は1〜100の範囲で指定してください" },
      allow_blank: true

    validates :dpi,
      inclusion: { in: Setting::PDF_DPI_OPTIONS, message: "は96、120、150、200のいずれかを指定してください" },
      allow_blank: true

    def initialize(attributes = {})
      super
      load_from_settings if attributes.empty?
    end

    def save
      return false unless valid?

      Setting.pdf_max_pages = max_pages.presence || Setting::DEFAULT_PDF_MAX_PAGES
      Setting.pdf_dpi = dpi.presence || Setting::DEFAULT_PDF_DPI
      true
    rescue => e
      errors.add(:base, e.message)
      false
    end

    def persisted?
      true
    end

    def to_key
      [ :pdf_settings ]
    end

    def model_name
      ActiveModel::Name.new(self, nil, "PdfSettings")
    end

    private

    def load_from_settings
      self.max_pages = Setting.effective_pdf_max_pages
      self.dpi = Setting.effective_pdf_dpi
    end
  end
end
