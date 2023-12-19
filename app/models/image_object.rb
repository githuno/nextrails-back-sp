class ImageObject < ApplicationRecord
  has_many :images

  def self.find_or_create_by(id:, user_id:)
    image_object = find_by(id:)
    return image_object if image_object.present?
    create(id:, created_by: user_id)
  end

  def main_image
    images.first&.image_path || ''
  end

  def condition3d_info
    if condition3d.nil?
      { "status": -1, "message": '未作成' }
    else
      parts = condition3d.split('#', 2)
      if parts.length == 2
        { "status": parts[0].to_i, "message": parts[1] }
      else
        { "status": -1, "message": '未知のエラー' }
      end
    end
  end
end
