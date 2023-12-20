class ImageObject < ApplicationRecord
  has_many :images, foreign_key: :object_id

  def self.find_or_create_by(id:, user_id:)
    image_object = find_by(id:)
    return image_object if image_object.present?

    create(id:, name: id, created_by: user_id) # nameを仮でidにしている
  end

  def main_image
    # もしimages.first&.image_pathのbasenameが36文字なら拡張子をmp4に変更して返す
    # それ以外ならimage_pathを返す
    # ただし、image_pathがnilの場合はnilを返す
    return unless images.first&.image_path

    basename = images.first.image_path.split('/').last.sub(/\.[^.]+\z/, '')
    if basename.length == 36
      images.first.image_path.sub('.png', '.mp4')
    else
      images.first.image_path
    end
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
