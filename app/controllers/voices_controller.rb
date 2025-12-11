class VoicesController < ApplicationController
  def generate
    voice_generation = VoiceGeneration.new(text: params[:text])

    if voice_generation.save
      VoiceGenerationJob.perform_async(voice_generation.id)

      render json: {
        id: voice_generation.id,
        status: voice_generation.status,
        message: "Voice generation started",
        status_url: "#{request.base_url}/voice_status/#{voice_generation.id}"
      }, status: :accepted
    else
      render json: {
        errors: voice_generation.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def status
    voice_generation = VoiceGeneration.find(params[:id])

    response_data = {
      id: voice_generation.id,
      status: voice_generation.status,
      text: voice_generation.text
    }

    if voice_generation.status == 'completed'
      response_data[:audio_url] = voice_generation.audio_url
    elsif voice_generation.status == 'failed'
      response_data[:error] = voice_generation.error_message
    end

    render json: response_data
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Voice generation not found" }, status: :not_found
  end
end
