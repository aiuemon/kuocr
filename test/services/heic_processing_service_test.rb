# frozen_string_literal: true

require "test_helper"

class HeicProcessingServiceTest < ActiveSupport::TestCase
  setup do
    @vips_available = check_vips_available
    @vips_heif_available = @vips_available && check_vips_heif_support
  end

  # heic? メソッドのテスト（libvips 不要）
  test "heic? は image/heic を true と判定する" do
    assert HeicProcessingService.heic?("image/heic")
  end

  test "heic? は image/heif を true と判定する" do
    assert HeicProcessingService.heic?("image/heif")
  end

  test "heic? は image/heic-sequence を true と判定する" do
    assert HeicProcessingService.heic?("image/heic-sequence")
  end

  test "heic? は image/heif-sequence を true と判定する" do
    assert HeicProcessingService.heic?("image/heif-sequence")
  end

  test "heic? は大文字小文字を区別しない" do
    assert HeicProcessingService.heic?("IMAGE/HEIC")
    assert HeicProcessingService.heic?("Image/Heif")
  end

  test "heic? は image/jpeg を false と判定する" do
    assert_not HeicProcessingService.heic?("image/jpeg")
  end

  test "heic? は image/png を false と判定する" do
    assert_not HeicProcessingService.heic?("image/png")
  end

  test "heic? は nil を false と判定する" do
    assert_not HeicProcessingService.heic?(nil)
  end

  test "heic? は空文字を false と判定する" do
    assert_not HeicProcessingService.heic?("")
  end

  # 変換テスト（libvips + libheif が必要）
  test "convert_to_png は HEIC を PNG に変換する" do
    skip "libvips がインストールされていません" unless @vips_available
    skip "libvips に HEIF サポートがありません" unless @vips_heif_available

    heic_data = create_sample_heic
    skip "実際の HEIC フィクスチャがありません（Issue #190）" if heic_data.blank?

    service = HeicProcessingService.new(heic_data, "photo.heic")

    result = service.convert_to_png

    assert_equal "photo.png", result[:filename]
    assert_equal "image/png", result[:content_type]
    assert result[:image_data].present?
    # PNG マジックバイトの確認
    assert_equal "\x89PNG".b, result[:image_data][0, 4]
  end

  test "convert_to_png は不正なデータで ConversionError を発生させる" do
    skip "libvips がインストールされていません" unless @vips_available

    service = HeicProcessingService.new("invalid heic data", "test.heic")

    assert_raises(HeicProcessingService::ConversionError) do
      service.convert_to_png
    end
  end

  private

  def check_vips_available
    require "vips"
    true
  rescue LoadError
    false
  end

  def check_vips_heif_support
    require "vips"
    Vips.get_suffixes.include?(".heic") || Vips.get_suffixes.include?(".heif")
  rescue StandardError
    false
  end

  def create_sample_heic
    # 実際の HEIC ファイルが必要な場合はフィクスチャを使用
    # ここではテスト用のダミーを返す（実際のテストはスキップされる）
    ""
  end
end
