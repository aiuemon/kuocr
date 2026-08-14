# frozen_string_literal: true

require "open3"
require "tmpdir"

# PDF ファイルを画像に変換するサービス
# poppler-utils の pdftoppm を使用して各ページを JPEG に変換する
class PdfProcessingService
  class Error < StandardError; end
  class PageLimitExceededError < Error; end
  class ConversionError < Error; end

  IMAGE_FORMAT = "jpeg"  # pdftoppm のオプション名
  FILE_EXTENSION = "jpg" # 出力ファイルの拡張子

  def initialize(pdf_data, filename)
    @pdf_data = pdf_data
    @filename = filename
    @max_pages = Setting.effective_pdf_max_pages
    @dpi = Setting.effective_pdf_dpi
  end

  # PDF のページ数を取得
  # @return [Integer] ページ数
  def page_count
    @page_count ||= count_pages
  end

  # ページ数が上限を超えているかチェック
  # @return [Boolean]
  def exceeds_page_limit?
    page_count > @max_pages
  end

  # PDF を画像に変換
  # @return [Array<Hash>] 各ページの { page_number:, image_data:, filename: }
  # @raise [PageLimitExceededError] ページ数が上限を超えている場合
  # @raise [ConversionError] 変換に失敗した場合
  def convert_to_images
    if exceeds_page_limit?
      raise PageLimitExceededError,
        "PDF のページ数（#{page_count}）が上限（#{@max_pages}）を超えています"
    end

    Dir.mktmpdir do |tmpdir|
      pdf_path = File.join(tmpdir, "input.pdf")
      File.binwrite(pdf_path, @pdf_data)

      output_prefix = File.join(tmpdir, "page")
      convert_pdf_to_images(pdf_path, output_prefix)

      collect_page_images(tmpdir)
    end
  end

  private

  def count_pages
    Dir.mktmpdir do |tmpdir|
      pdf_path = File.join(tmpdir, "input.pdf")
      File.binwrite(pdf_path, @pdf_data)

      stdout, stderr, status = Open3.capture3("pdfinfo", pdf_path)
      raise ConversionError, "pdfinfo の実行に失敗しました: #{stderr}" unless status.success?

      match = stdout.match(/Pages:\s*(\d+)/)
      raise ConversionError, "PDF のページ数を取得できませんでした" unless match

      match[1].to_i
    end
  rescue Errno::ENOENT
    raise ConversionError, "poppler-utils がインストールされていません。PDF 処理には poppler-utils が必要です。"
  end

  def convert_pdf_to_images(pdf_path, output_prefix)
    # pdftoppm -jpeg -r <dpi> input.pdf output_prefix
    _stdout, stderr, status = Open3.capture3(
      "pdftoppm",
      "-#{IMAGE_FORMAT}",
      "-r", @dpi.to_s,
      pdf_path,
      output_prefix
    )
    raise ConversionError, "pdftoppm の実行に失敗しました: #{stderr}" unless status.success?
  rescue Errno::ENOENT
    raise ConversionError, "poppler-utils がインストールされていません。PDF 処理には poppler-utils が必要です。"
  end

  def collect_page_images(tmpdir)
    base_name = File.basename(@filename, ".*")
    images = []

    # pdftoppm は page-01.jpg, page-02.jpg のように出力する
    Dir.glob(File.join(tmpdir, "page-*.#{FILE_EXTENSION}")).sort.each_with_index do |image_path, index|
      page_number = index + 1
      images << {
        page_number: page_number,
        image_data: File.binread(image_path),
        filename: "#{base_name}_#{page_number}.#{FILE_EXTENSION}"
      }
    end

    raise ConversionError, "PDF から画像を生成できませんでした" if images.empty?

    images
  end
end
