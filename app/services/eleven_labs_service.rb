class ElevenLabsService
  include HTTParty
  base_uri 'https://api.elevenlabs.io/v1'

  def initialize
    @api_key = ENV['ELEVEN_LABS_API_KEY']
    @voice_id = ENV['ELEVEN_LABS_VOICE_ID'] || 'EXAVITQu4vr4xnSDxMaL' # Default voice
  end

  def generate_speech(text)
    Rails.logger.info "ElevenLabs API Key: #{@api_key[0..10]}..." if @api_key
    Rails.logger.info "Voice ID: #{@voice_id}"

    response = self.class.post(
      "/text-to-speech/#{@voice_id}",
      headers: headers,
      body: body(text).to_json
    )

    Rails.logger.info "ElevenLabs Response: #{response.code}"
    Rails.logger.info "Response body: #{response.body[0..200]}" unless response.success?

    if response.success?
      response.body
    else
      raise "ElevenLabs API error: #{response.code} - #{response.message} - #{response.body}"
    end
  end

  private

  def headers
    {
      'Accept' => 'audio/mpeg',
      'Content-Type' => 'application/json',
      'xi-api-key' => @api_key
    }
  end

  def body(text)
    {
      text: text,
      model_id: 'eleven_turbo_v2_5',
      voice_settings: {
        stability: 0.5,
        similarity_boost: 0.75
      }
    }
  end
end
