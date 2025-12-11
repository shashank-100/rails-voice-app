class VoiceGeneration < ApplicationRecord
  STATUSES = %w[pending processing completed failed].freeze

  validates :text, presence: true
  validates :status, inclusion: { in: STATUSES }

  before_validation :set_default_status, on: :create

  scope :pending, -> { where(status: 'pending') }
  scope :processing, -> { where(status: 'processing') }
  scope :completed, -> { where(status: 'completed') }
  scope :failed, -> { where(status: 'failed') }

  def audio_url
    # Returns the full Supabase URL stored in audio_file_path
    audio_file_path
  end

  private

  def set_default_status
    self.status ||= 'pending'
  end
end
