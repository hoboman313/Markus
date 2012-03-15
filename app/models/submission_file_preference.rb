class SubmissionFilePreference < ActiveRecord::Base
  belongs_to :submission_file
  belongs_to :user
  validates_presence_of :encoding
end
