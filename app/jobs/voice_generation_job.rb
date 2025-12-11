class VoiceGenerationJob
  include Sidekiq::Job

  def perform(voice_generation_id)
    voice_generation = VoiceGeneration.find(voice_generation_id)
    voice_generation.update(status: 'processing')

    # Generate audio using ElevenLabs
    eleven_labs_service = ElevenLabsService.new
    audio_data = eleven_labs_service.generate_speech(voice_generation.text)

    # Upload to Supabase storage
    storage_service = SupabaseStorageService.new
    filename = "voice_#{voice_generation.id}_#{Time.now.to_i}.mp3"
    audio_url = storage_service.upload_file(filename, audio_data)

    # Update record with Supabase URL
    voice_generation.update(
      status: 'completed',
      audio_file_path: audio_url
    )
  rescue StandardError => e
    voice_generation.update(
      status: 'failed',
      error_message: e.message
    )
    raise e
  end
end
