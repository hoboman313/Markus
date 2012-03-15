class CreateSubmissionFilePreferences < ActiveRecord::Migration
  def self.up
    create_table :submission_file_preferences do |t|
      t.references :user
      t.references :submission_file
      t.string :encoding, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :submission_file_preferences
  end
end
