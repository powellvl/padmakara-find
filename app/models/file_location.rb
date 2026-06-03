class FileLocation < ApplicationRecord
  belongs_to :catalogued_file

  validates :path, presence: true, uniqueness: true
  validates :mtime, presence: true
  validates :last_seen_at, presence: true

  scope :active,   -> { where(missing_since: nil) }
  scope :missing,  -> { where.not(missing_since: nil) }

  def active?
    missing_since.nil?
  end

  def extension
    File.extname(path).downcase
  end

  def filename
    File.basename(path)
  end

  def top_folder
    # Returns the first path component below the NAS source root.
    relative = Pathname.new(path).relative_path_from(Pathname.new(NasSource.root))
    relative.each_filename.first || "(root)"
  rescue ArgumentError
    "(root)"
  end
end
