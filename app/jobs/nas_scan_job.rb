class NasScanJob < ApplicationJob
  queue_as :default

  # Idempotent: enqueuing multiple times is safe.
  # The scanner itself enforces read-only access to the NAS.
  def perform
    NasScanner.new.call
  end
end
