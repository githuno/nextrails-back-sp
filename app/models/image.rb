class Image < ApplicationRecord
  belongs_to :object, class_name: 'ImageObject', foreign_key: 'object_id'
  has_one_attached :file

  # def self.fetch_images(object_id, cnt)
  #   if cnt < 0
  #     where(object_id:).order(updated_at: :desc).pluck(:image_path)
  #   else
  #     where(object_id:).order(updated_at: :desc).limit(cnt).pluck(:image_path)
  #   end
  # end
end
