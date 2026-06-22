# frozen_string_literal: true

require "tmpdir"

# HEIC/HEIF 画像を PNG に変換するサービス
# libvips + libheif を使用
class HeicProcessingService
  class Error < StandardError; end
  class ConversionError < Error; end

  HEIC_CONTENT_TYPES = %w[
    image/heic
    image/heif
    image/heic-sequence
    image/heif-sequence
  ].freeze

  # @param image_data [String] HEIC 画像のバイナリデータ
  # @param filename [String] 元のファイル名
  def initialize(image_data, filename)
    @image_data = image_data
    @filename = filename
  end

  # HEIC を PNG に変換
  # @return [Hash] { image_data:, filename:, content_type: }
  # @raise [ConversionError] 変換に失敗した場合
  def convert_to_png
    require "vips"

    Dir.mktmpdir do |tmpdir|
      input_path = File.join(tmpdir, "input.heic")
      output_path = File.join(tmpdir, "output.png")

      File.binwrite(input_path, @image_data)

      begin
        image = Vips::Image.new_from_file(input_path)
        image.write_to_file(output_path)
      rescue Vips::Error => e
        raise ConversionError, "HEIC から PNG への変換に失敗しました: #{e.message}"
      end

      base_name = File.basename(@filename, ".*")
      {
        image_data: File.binread(output_path),
        filename: "#{base_name}.png",
        content_type: "image/png"
      }
    end
  end

  # 指定された content_type が HEIC/HEIF かどうかを判定
  # @param content_type [String]
  # @return [Boolean]
  def self.heic?(content_type)
    HEIC_CONTENT_TYPES.include?(content_type&.downcase)
  end
end
