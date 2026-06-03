module NasSource
  # In development, falls back to tmp/nas_sample (seeded with representative files).
  # On the production server, set NAS_SOURCE_ROOT to the actual NAS mount point.
  ROOT = Pathname.new(
    ENV.fetch("NAS_SOURCE_ROOT", Rails.root.join("tmp/nas_sample").to_s)
  ).freeze

  def self.root
    ROOT
  end
end
