module OcrApi
  class OpenAiCompatibleProvider < BaseProvider
    # OpenAI 互換 API に渡すオプションキー（Ollama 固有のキーは除外）
    ALLOWED_OPTION_KEYS = %w[
      temperature max_tokens top_p frequency_penalty presence_penalty seed
    ].freeze

    private

    def build_request(uri, image_data, content_type, prompt)
      image_b64 = Base64.strict_encode64(image_data)
      mime_type = content_type.presence || "image/jpeg"
      payload = {
        model: Setting.ocr_model,
        messages: [
          {
            role: "user",
            content: [
              {
                type: "image_url",
                image_url: { url: "data:#{mime_type};base64,#{image_b64}" }
              },
              {
                type: "text",
                text: prompt
              }
            ]
          }
        ],
        stream: true
      }
      payload.merge!(filtered_options)
      request = build_base_http_request(uri)
      request.body = payload.to_json
      request
    end

    def extract_text(body)
      text = ""
      body.each_line do |line|
        line = line.strip
        next if line.empty?
        next unless line.start_with?("data: ")

        json_str = line.delete_prefix("data: ")
        next if json_str == "[DONE]"

        begin
          data = JSON.parse(json_str, symbolize_names: true)
          content = data.dig(:choices, 0, :delta, :content)
          text += content.to_s if content
        rescue JSON::ParserError
          next
        end
      end
      remove_think_tags(text)
    end

    def filtered_options
      Setting.effective_ocr_options.slice(*ALLOWED_OPTION_KEYS)
    end
  end
end
