class Image < ApplicationRecord
  belongs_to :object, class_name: 'ImageObject', foreign_key: 'object_id'
  has_one_attached :file
  has_one_attached :html_file

  # for Video------------------------------------------------------------------>
  def generate_presigned_url(key)
    s3_resource.bucket(ENV['S3_BUCKET']).object(key).presigned_url(:put, expires_in: 3600)
  end

  def delete_related_s3files
    obj_id = self.object_id
    base_name = self.image_path.split('/').last.sub(/\.[^.]+\z/, '')
    # self.image_pathの拡張子がpngなら何もしない
    return if File.extname(self.image_path) == '.png'

    s3 = s3_resource

    extensions = ['.png' '.html', '.mp4'] # 削除対象の拡張子
    extensions.each do |extension|
      key = "#{obj_id}/#{base_name}#{extension}"
      s3.bucket(ENV['S3_BUCKET']).object(key).delete
    end
  end

  private

  def s3_resource
    require 'aws-sdk-s3'
    return Aws::S3::Resource.new(
      region: ENV['AWS_REGION'],
      access_key_id: ENV['AWS_ACCESS_KEY'],
      secret_access_key: ENV['AWS_SECRET_KEY'],
      endpoint: ENV['AWS_ENDPOINT']
    )
  end
  # <------------------------------------------------------------------for Video
end