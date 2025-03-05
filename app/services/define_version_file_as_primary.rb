class DefineVersionFileAsPrimary
  def initialize(version, attachment)
    @version = version
    @attachment = attachment
  end

  def call
    ActiveRecord::Base.transaction do
      @version.files_attachments.update_all(primary: false)
      @attachment.update!(primary: true)
    end
  end
end
