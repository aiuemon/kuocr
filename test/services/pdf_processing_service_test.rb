# frozen_string_literal: true

require "test_helper"

class PdfProcessingServiceTest < ActiveSupport::TestCase
  setup do
    Rails.cache.clear
    Setting.pdf_dpi = Setting::DEFAULT_PDF_DPI
    @poppler_available = system("which pdfinfo > /dev/null 2>&1")
  end

  # ページ数上限チェックのテスト
  test "exceeds_page_limit? は上限を超えた場合 true を返す" do
    skip "poppler-utils がインストールされていません" unless @poppler_available

    Setting.pdf_max_pages = 1
    pdf_data = create_sample_pdf(2)
    service = PdfProcessingService.new(pdf_data, "test.pdf")

    assert service.exceeds_page_limit?
  end

  test "exceeds_page_limit? は上限以下の場合 false を返す" do
    skip "poppler-utils がインストールされていません" unless @poppler_available

    Setting.pdf_max_pages = 10
    pdf_data = create_sample_pdf(2)
    service = PdfProcessingService.new(pdf_data, "test.pdf")

    assert_not service.exceeds_page_limit?
  end

  # 変換テスト
  test "convert_to_images は各ページの画像データを返す" do
    skip "poppler-utils がインストールされていません" unless @poppler_available

    Setting.pdf_max_pages = 10
    pdf_data = create_sample_pdf(2)
    service = PdfProcessingService.new(pdf_data, "document.pdf")

    result = service.convert_to_images

    assert_equal 2, result.size
    assert_equal 1, result[0][:page_number]
    assert_equal "document_1.jpg", result[0][:filename]
    assert result[0][:image_data].present?
    assert_equal 2, result[1][:page_number]
    assert_equal "document_2.jpg", result[1][:filename]
  end

  test "convert_pdf_to_images は設定された DPI を pdftoppm に渡す" do
    Setting.pdf_dpi = 96
    service = PdfProcessingService.new("pdf data", "test.pdf")
    status = Object.new
    status.define_singleton_method(:success?) { true }
    captured_args = nil
    original_capture3 = Open3.method(:capture3)

    Open3.define_singleton_method(:capture3) do |*args|
      captured_args = args
      [ "", "", status ]
    end

    begin
      service.send(:convert_pdf_to_images, "input.pdf", "page")
    ensure
      Open3.define_singleton_method(:capture3, original_capture3)
    end

    assert_equal [ "pdftoppm", "-jpeg", "-r", "96", "input.pdf", "page" ], captured_args
  end

  test "convert_to_images はページ上限を超えた場合 PageLimitExceededError を発生させる" do
    skip "poppler-utils がインストールされていません" unless @poppler_available

    Setting.pdf_max_pages = 1
    pdf_data = create_sample_pdf(2)
    service = PdfProcessingService.new(pdf_data, "test.pdf")

    assert_raises(PdfProcessingService::PageLimitExceededError) do
      service.convert_to_images
    end
  end

  test "convert_to_images は不正な PDF データで ConversionError を発生させる" do
    skip "poppler-utils がインストールされていません" unless @poppler_available

    Setting.pdf_max_pages = 10
    service = PdfProcessingService.new("invalid pdf data", "test.pdf")

    assert_raises(PdfProcessingService::ConversionError) do
      service.page_count
    end
  end

  # Forms::PdfSettingsForm のテスト（poppler 不要）
  test "PdfSettingsForm は有効な値を保存できる" do
    form = Forms::PdfSettingsForm.new(max_pages: 50, dpi: 150)
    assert form.valid?
    assert form.save
    assert_equal 50, Setting.pdf_max_pages
    assert_equal 150, Setting.pdf_dpi
  end

  test "PdfSettingsForm は空の場合デフォルト値を使用する" do
    form = Forms::PdfSettingsForm.new(max_pages: "", dpi: "")
    assert form.valid?
    assert form.save
    assert_equal Setting::DEFAULT_PDF_MAX_PAGES, Setting.pdf_max_pages
    assert_equal Setting::DEFAULT_PDF_DPI, Setting.pdf_dpi
  end

  test "PdfSettingsForm は 0 以下の値を拒否する" do
    form = Forms::PdfSettingsForm.new(max_pages: 0)
    assert_not form.valid?
    assert form.errors[:max_pages].present?
  end

  test "PdfSettingsForm は 100 を超える値を拒否する" do
    form = Forms::PdfSettingsForm.new(max_pages: 101)
    assert_not form.valid?
    assert form.errors[:max_pages].present?
  end

  test "PdfSettingsForm は選択肢外の DPI を拒否する" do
    form = Forms::PdfSettingsForm.new(max_pages: 20, dpi: 72)
    assert_not form.valid?
    assert form.errors[:dpi].present?
  end

  test "PdfSettingsForm は設定から値を読み込む" do
    Setting.pdf_max_pages = 30
    Setting.pdf_dpi = 96
    form = Forms::PdfSettingsForm.new
    assert_equal 30, form.max_pages
    assert_equal 96, form.dpi
  end

  private

  # テスト用の簡易 PDF を作成
  # 実際の PDF 作成には prawn gem などが必要だが、
  # ここでは poppler が処理できる最小限の PDF を生成
  def create_sample_pdf(pages = 1)
    # 最小限の PDF 構造
    objects = []
    objects << "1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj"

    page_refs = (1..pages).map { |i| "#{i + 2} 0 R" }.join(" ")
    objects << "2 0 obj\n<< /Type /Pages /Kids [#{page_refs}] /Count #{pages} >>\nendobj"

    pages.times do |i|
      obj_num = i + 3
      objects << "#{obj_num} 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] >>\nendobj"
    end

    xref_offset = 0
    body = objects.join("\n")
    xref_offset = "%PDF-1.4\n".length + body.length + 1

    pdf = "%PDF-1.4\n#{body}\nxref\n0 #{objects.size + 1}\n0000000000 65535 f \n"
    offset = 9 # %PDF-1.4\n の長さ
    objects.each do |obj|
      pdf += format("%010d 00000 n \n", offset)
      offset += obj.length + 1
    end
    pdf += "trailer\n<< /Size #{objects.size + 1} /Root 1 0 R >>\nstartxref\n#{xref_offset}\n%%EOF"

    pdf
  end
end
