class UpdateVideoIdForYoutubeInVideos < ActiveRecord::Migration[5.2]
  def up
    Video.where(video_type: 'youtube').find_each do |video|
      video.update(
        url: video.url.split('/').last
      )
    end
  end

  def down
  end
end
