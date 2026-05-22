require "net/http"
require "uri"
require "json"
require "base64"
require "openssl"

module OcrApi
  class BaseProvider
    def initialize(endpoint:, api_key:, timeout:, skip_ssl_verify:)
      @endpoint = endpoint
      @api_key = api_key
      @timeout = timeout
      @skip_ssl_verify = skip_ssl_verify
    end

    def transcribe(image_data:, content_type: nil, prompt:)
      uri = URI.parse(@endpoint)
      http = build_http_client(uri)
      request = build_request(uri, image_data, content_type, prompt)
      response = execute_request(http, request)
      parse_response(response)
    end

    private

    def build_http_client(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE if @skip_ssl_verify
      http.open_timeout = @timeout
      http.read_timeout = @timeout
      http
    end

    def build_request(_uri, _image_data, _content_type, _prompt)
      raise NotImplementedError
    end

    def extract_text(_body)
      raise NotImplementedError
    end

    def build_base_http_request(uri)
      request = Net::HTTP::Post.new(uri.request_uri)
      request["Content-Type"] = "application/json"
      request["Accept"] = "application/json"
      request["Authorization"] = "Bearer #{@api_key}" if @api_key.present?
      request
    end

    def execute_request(http, request)
      http.request(request)
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      raise OcrApiClient::TimeoutError, "API request timed out: #{e.message}"
    rescue StandardError => e
      raise OcrApiClient::RequestError, "API request failed: #{e.message}"
    end

    def parse_response(response)
      case response.code.to_i
      when 200..299
        extract_text(response.body)
      when 401
        raise OcrApiClient::RequestError, "Authentication failed: Invalid API key"
      when 404
        raise OcrApiClient::RequestError, "API endpoint not found"
      when 429
        raise OcrApiClient::RequestError, "Rate limit exceeded"
      when 500..599
        raise OcrApiClient::RequestError, "API server error: #{response.code} - #{response.body.to_s.truncate(500)}"
      else
        raise OcrApiClient::RequestError, "Unexpected response: #{response.code} - #{response.body}"
      end
    end

    def remove_think_tags(text)
      text.gsub(%r{<think>.*?</think>}m, "").strip
    end
  end
end
