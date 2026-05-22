module OcrApi
  class OllamaProvider < BaseProvider
    private

    def build_request(uri, image_data, _content_type, prompt)
      image_b64 = Base64.strict_encode64(image_data)
      payload = {
        model: Setting.ocr_model,
        prompt: prompt,
        images: [ image_b64 ],
        stream: true,
        options: Setting.effective_ocr_options
      }
      request = build_base_http_request(uri)
      request.body = payload.to_json
      request
    end

    def extract_text(body)
      text = ""
      body.each_line do |line|
        line = line.strip
        next if line.empty?

        begin
          data = JSON.parse(line, symbolize_names: true)
          text += data[:response].to_s
        rescue JSON::ParserError
          next
        end
      end
      remove_think_tags(text)
    end
  end
end
