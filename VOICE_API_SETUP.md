# Voice Generation API - Setup & Usage Guide

## Overview

This Rails API provides a `/generate_voice` endpoint that accepts text input, converts it to speech using ElevenLabs API, stores the audio file locally (with S3 support ready for later), and returns the audio file URL.

## Architecture

- **Asynchronous Processing**: Uses Sidekiq for background job processing
- **Database Tracking**: VoiceGeneration model tracks job status
- **Storage**: Currently using local storage in `public/audio/` (S3-ready)
- **API Integration**: ElevenLabs API for text-to-speech conversion

## Setup Steps

### 1. Environment Variables

Create a `.env` file in the project root and add your ElevenLabs API credentials:

```bash
ELEVEN_LABS_API_KEY=your_api_key_here
ELEVEN_LABS_VOICE_ID=EXAVITQu4vr4xnSDxMaL  # Optional: default voice provided
```

To get your API key:
1. Sign up at https://elevenlabs.io
2. Go to Profile Settings → API Key
3. Copy your API key

### 2. Install Dependencies

```bash
bundle install
```

### 3. Database Setup

The migration has already been run, but if you need to run it again:

```bash
rails db:migrate
```

### 4. Start Redis

Sidekiq requires Redis to be running:

```bash
# On macOS with Homebrew:
brew services start redis

# Or run Redis directly:
redis-server
```

### 5. Start Sidekiq

In a separate terminal window:

```bash
bundle exec sidekiq
```

### 6. Start Rails Server

```bash
rails server
```

## API Endpoints

### POST /generate_voice

Generate a new voice from text.

**Request:**
```bash
curl -X POST http://localhost:3000/generate_voice \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello, this is a test of the voice generation API."}'
```

**Response (202 Accepted):**
```json
{
  "id": 1,
  "status": "pending",
  "message": "Voice generation started",
  "status_url": "http://localhost:3000/voice_status/1"
}
```

**Error Response (422 Unprocessable Entity):**
```json
{
  "errors": ["Text can't be blank"]
}
```

### GET /voice_status/:id

Check the status of a voice generation job.

**Request:**
```bash
curl http://localhost:3000/voice_status/1
```

**Response (pending/processing):**
```json
{
  "id": 1,
  "status": "processing",
  "text": "Hello, this is a test of the voice generation API."
}
```

**Response (completed):**
```json
{
  "id": 1,
  "status": "completed",
  "text": "Hello, this is a test of the voice generation API.",
  "audio_url": "/audio/voice_1_1234567890.mp3"
}
```

**Response (failed):**
```json
{
  "id": 1,
  "status": "failed",
  "text": "Hello, this is a test of the voice generation API.",
  "error": "ElevenLabs API error: 401 - Unauthorized"
}
```

## File Structure

```
app/
├── controllers/
│   └── voices_controller.rb         # API endpoints
├── models/
│   └── voice_generation.rb          # Database model
├── services/
│   └── eleven_labs_service.rb       # ElevenLabs API integration
└── jobs/
    └── voice_generation_job.rb      # Sidekiq background job

public/
└── audio/                            # Generated audio files stored here

config/
└── routes.rb                         # API routes defined here
```

## Key Components

### VoiceGeneration Model

Tracks voice generation jobs with the following statuses:
- `pending`: Job created, waiting to be processed
- `processing`: Currently generating audio
- `completed`: Audio file ready
- `failed`: Error occurred during generation

### VoiceGenerationJob

Sidekiq background job that:
1. Updates status to 'processing'
2. Calls ElevenLabs API to generate speech
3. Saves audio file to `public/audio/`
4. Updates record with file path and 'completed' status
5. Handles errors and updates status to 'failed' if needed

### ElevenLabsService

Handles API communication with ElevenLabs:
- Uses HTTParty for HTTP requests
- Configurable voice ID and model
- Uses `eleven_turbo_v2_5` model (free tier compatible)
- Returns binary audio data (MP3 format)

## Testing the API

### Full Workflow Test

```bash
# 1. Generate voice
response=$(curl -s -X POST http://localhost:3000/generate_voice \
  -H "Content-Type: application/json" \
  -d '{"text": "Testing voice generation"}')

echo $response

# Extract ID from response
id=$(echo $response | grep -o '"id":[0-9]*' | grep -o '[0-9]*')

# 2. Check status (wait a few seconds)
sleep 3
curl http://localhost:3000/voice_status/$id

# 3. Download audio file (once completed)
# The audio_url will be something like /audio/voice_1_1234567890.mp3
# Access it at: http://localhost:3000/audio/voice_1_1234567890.mp3
```

## Upgrading to S3 Storage (Future)

When ready to migrate to S3:

1. Configure AWS credentials in environment variables
2. Update `VoiceGenerationJob#save_audio_file` to use AWS SDK S3
3. Update `VoiceGeneration#audio_url` to return S3 URL
4. The aws-sdk-s3 gem is already installed

## Monitoring

### Check Sidekiq Status

```bash
# View Sidekiq logs
tail -f log/sidekiq.log

# Check Redis for queued jobs
redis-cli
> LLEN queue:default
```

### Database Queries

```ruby
# Rails console
rails console

# Check all voice generations
VoiceGeneration.all

# Check pending jobs
VoiceGeneration.pending

# Check failed jobs
VoiceGeneration.failed
```

## Error Handling

Common errors and solutions:

1. **"ElevenLabs API error: 401"**
   - Check that ELEVEN_LABS_API_KEY is set correctly
   - Verify API key is valid on ElevenLabs dashboard

2. **Sidekiq jobs not processing**
   - Ensure Redis is running: `redis-cli ping`
   - Check Sidekiq is running: `ps aux | grep sidekiq`

3. **Audio files not saving**
   - Check write permissions on `public/audio/` directory
   - Verify disk space is available

## Rate Limiting

The app has rack-attack installed for rate limiting. You can configure rate limits in an initializer if needed.

## Next Steps

- Add authentication/authorization
- Implement rate limiting per user
- Add webhook notifications for job completion
- Migrate to S3 for production storage
- Add support for multiple voices
- Add audio format options (MP3, WAV, etc.)
