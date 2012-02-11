class AddEncodingToSubmissionFiles < ActiveRecord::Migration
  def self.up
    add_column :submission_files, :encoding, :string
  end

  def self.down
    remove_column :submission_files, :encoding
  end
end
