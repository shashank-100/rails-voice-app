class CreateVoiceGenerations < ActiveRecord::Migration[7.1]
  def change
    create_table :voice_generations do |t|
      t.text :text
      t.string :status
      t.string :audio_file_path
      t.text :error_message

      t.timestamps
    end
  end
end
