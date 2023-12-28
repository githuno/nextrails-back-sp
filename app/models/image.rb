class Image < ApplicationRecord
  belongs_to :object, class_name: 'ImageObject', foreign_key: 'object_id'
  has_one_attached :file, dependent: :destroy
  has_one_attached :html_file, dependent: :destroy

  def self.upload_image(obj, image_data, user_id, now)
    begin
      image_bytes = Base64.decode64(image_data)
      io = StringIO.new(image_bytes)
      filename = "#{now}.png"
      key = "#{obj.id}/#{filename}"
      image_path = "#{ENV['S3_PUBLIC_URL']}/#{key}"
      image = Image.create!(object_id: obj.id, image_path: image_path, updated_by: user_id) 
      image.file.attach(io: io, key: key, filename: filename, content_type: 'image/png')
      image
    rescue StandardError => e
      raise "Failed to upload image: #{e.message}"
    end
  end

  # for Video------------------------------------------------------------------>
  def generate_presigned_url(key)
    begin
      s3_resource = S3ResourceService.instance.resource
      s3_resource.bucket(ENV['S3_BUCKET']).object(key).presigned_url(:put, expires_in: 3600)
    rescue Aws::S3::Errors::ServiceError => e
      raise "Failed to generate presigned URL: #{e.message}"
    end
  end

  def delete_related_s3files
    begin
      obj_id = self.object_id
      base_name = self.image_path.split('/').last.sub(/\.[^.]+\z/, '')
      return if File.extname(self.image_path) == '.png'
  
      extensions = ['.png', '.html', '.mp4'] # 削除対象の拡張子
      extensions.each do |extension|
        key = "#{obj_id}/#{base_name}#{extension}"
        S3ResourceService.instance.resource.bucket(ENV['S3_BUCKET']).object(key).delete
      end
    rescue Aws::S3::Errors::ServiceError => e
      raise "Failed to delete related S3 files: #{e.message}"
    end
  end
  # <------------------------------------------------------------------for Video
end