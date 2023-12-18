class Image < ApplicationRecord
  def self.fetch_images(object_id, cnt)
    if cnt < 0
      where(object_id:).order(updated_at: :desc).pluck(:image_path)
    else
      where(object_id:).order(updated_at: :desc).limit(cnt).pluck(:image_path)
    end
  end
end
