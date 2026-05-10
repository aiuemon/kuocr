require "nokogiri"
require "net/http"
require "uri"

class SamlMetadataParser
  SAML_NAMESPACES = {
    "md" => "urn:oasis:names:tc:SAML:2.0:metadata",
    "ds" => "http://www.w3.org/2000/09/xmldsig#"
  }.freeze

  Result = Struct.new(:success?, :data, :error, keyword_init: true)

  class << self
    def parse_xml(xml_content)
      new.parse_xml(xml_content)
    end

    def fetch_and_parse(url)
      new.fetch_and_parse(url)
    end
  end

  def parse_xml(xml_content)
    return Result.new(success?: false, error: "XML が空です") if xml_content.blank?

    doc = Nokogiri::XML(xml_content)
    doc.remove_namespaces! if doc.namespaces.any?

    entity_descriptor = doc.at_xpath("//EntityDescriptor") || doc.at_xpath("//md:EntityDescriptor", SAML_NAMESPACES)
    return Result.new(success?: false, error: "EntityDescriptor が見つかりません") unless entity_descriptor

    idp_descriptor = entity_descriptor.at_xpath(".//IDPSSODescriptor") ||
                     entity_descriptor.at_xpath(".//md:IDPSSODescriptor", SAML_NAMESPACES)
    return Result.new(success?: false, error: "IDPSSODescriptor が見つかりません") unless idp_descriptor

    data = {
      entity_id: extract_entity_id(entity_descriptor),
      idp_sso_url: extract_sso_url(idp_descriptor),
      idp_slo_url: extract_slo_url(idp_descriptor),
      idp_cert: extract_certificate(idp_descriptor),
      name: extract_name(entity_descriptor)
    }

    Result.new(success?: true, data: data)
  rescue Nokogiri::XML::SyntaxError => e
    Result.new(success?: false, error: "XML パースエラー: #{e.message}")
  rescue StandardError => e
    Result.new(success?: false, error: "予期しないエラー: #{e.message}")
  end

  def fetch_and_parse(url)
    return Result.new(success?: false, error: "URL が空です") if url.blank?

    uri = URI.parse(url)
    return Result.new(success?: false, error: "無効な URL です") unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)

    response = fetch_url(uri)
    return Result.new(success?: false, error: "メタデータの取得に失敗しました: HTTP #{response.code}") unless response.is_a?(Net::HTTPSuccess)

    parse_xml(response.body)
  rescue URI::InvalidURIError
    Result.new(success?: false, error: "無効な URL 形式です")
  rescue Net::OpenTimeout, Net::ReadTimeout
    Result.new(success?: false, error: "タイムアウトしました")
  rescue SocketError, Errno::ECONNREFUSED => e
    Result.new(success?: false, error: "接続できませんでした: #{e.message}")
  rescue StandardError => e
    Result.new(success?: false, error: "予期しないエラー: #{e.message}")
  end

  private

  def fetch_url(uri, redirect_limit = 5)
    raise "リダイレクト回数が上限を超えました" if redirect_limit == 0

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")
    http.open_timeout = 10
    http.read_timeout = 30

    request = Net::HTTP::Get.new(uri)
    request["User-Agent"] = "kuocr/1.0"
    request["Accept"] = "application/xml, text/xml"

    response = http.request(request)

    if response.is_a?(Net::HTTPRedirection)
      new_uri = URI.parse(response["location"])
      new_uri = URI.join(uri, new_uri) unless new_uri.host
      return fetch_url(new_uri, redirect_limit - 1)
    end

    response
  end

  def extract_entity_id(entity_descriptor)
    entity_descriptor["entityID"]
  end

  def extract_sso_url(idp_descriptor)
    sso_service = idp_descriptor.at_xpath(
      ".//SingleSignOnService[@Binding='urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect']"
    ) || idp_descriptor.at_xpath(
      ".//SingleSignOnService[@Binding='urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST']"
    ) || idp_descriptor.at_xpath(".//SingleSignOnService")

    sso_service&.[]("Location")
  end

  def extract_slo_url(idp_descriptor)
    slo_service = idp_descriptor.at_xpath(
      ".//SingleLogoutService[@Binding='urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect']"
    ) || idp_descriptor.at_xpath(
      ".//SingleLogoutService[@Binding='urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST']"
    ) || idp_descriptor.at_xpath(".//SingleLogoutService")

    slo_service&.[]("Location")
  end

  def extract_certificate(idp_descriptor)
    cert_node = idp_descriptor.at_xpath(".//KeyDescriptor[@use='signing']//X509Certificate") ||
                idp_descriptor.at_xpath(".//KeyDescriptor//X509Certificate") ||
                idp_descriptor.at_xpath(".//X509Certificate")

    return nil unless cert_node

    cert_text = cert_node.text.strip.gsub(/\s+/, "")
    format_certificate(cert_text)
  end

  def format_certificate(cert_text)
    return nil if cert_text.blank?

    lines = cert_text.scan(/.{1,64}/)
    "-----BEGIN CERTIFICATE-----\n#{lines.join("\n")}\n-----END CERTIFICATE-----"
  end

  def extract_name(entity_descriptor)
    # Organization の DisplayName を優先
    org_name = entity_descriptor.at_xpath(".//Organization/OrganizationDisplayName")&.text ||
               entity_descriptor.at_xpath(".//Organization/OrganizationName")&.text

    return org_name if org_name.present?

    # entityID からドメイン部分を抽出
    entity_id = entity_descriptor["entityID"]
    return nil unless entity_id

    if entity_id.start_with?("http")
      URI.parse(entity_id).host
    else
      entity_id.split("/").first
    end
  rescue URI::InvalidURIError
    nil
  end
end
