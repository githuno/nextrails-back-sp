require 'open3'
require 'net/http'
require 'uri'
require 'json'
require 'openssl'

class ImageObject < ApplicationRecord
  has_many :images, foreign_key: :object_id, dependent: :destroy
  has_one_attached :ply_file, dependent: :destroy
  has_one_attached :splat_file, dependent: :destroy

  def self.create_if_none(params)
    ImageObject.find_by(id: params[:object_id]) ||
      ImageObject.create!(id: params[:object_id], name: params[:object_id], created_by: params[:user_id])
  end

  def main_image
    png_image = images.find { |image| image.image_path.end_with?('.png') } # front側でmp4処理ができそうなら、ここを変更する
    png_image&.image_path || images.first&.image_path || ''
  end

  def info
    {
      "created_by": created_by,
      "id": id,
      "name": name,
      "description": description,
      "created_at": created_at,
      "updated_at": updated_at,
      "main_image": main_image,
      "cdt3d_status": condition3d_info[:status],
      "cdt3d_msg": condition3d_info[:message]
    }
  end
  
  private

  def condition3d_info
    if condition3d.nil?
      { "status": -1, "message": '未作成' }
    else
      parts = condition3d.split('#', 2)
      if parts.length == 2
        { "status": parts[0].to_i, "message": parts[1] }
      else
        Rails.logger.warn "Unexpected format for condition3d: #{condition3d}"
        { "status": -1, "message": '未知のエラー' }
      end
    end
  end
end
