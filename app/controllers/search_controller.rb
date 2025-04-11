class SearchController < ApplicationController
  def index
    @query = params[:query]

    if @query.present?
      @texts = Text.distinct.joins(translations: { versions: :files_blobs }).where("
        texts.title_tibetan LIKE :query
        OR texts.title_phonetics LIKE :query
        OR versions.title LIKE :query
        OR active_storage_blobs.filename LIKE :query",
        query: "%#{@query}%")
      @versions = Version.distinct.joins(:files_blobs).where("
        title LIKE :query
        OR active_storage_blobs.filename LIKE :query",
        query: "%#{@query}%")
      @files = ActiveStorage::Blob.where(
        "filename LIKE :query",
        query: "%#{@query}%")
    else
      @texts = Text.joins(translations: :versions)
      @versions = Version.joins(translation: :text)
    end
  end
end
