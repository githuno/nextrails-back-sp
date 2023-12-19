class Image < ApplicationRecord
  belongs_to :object, class_name: 'ImageObject', foreign_key: 'object_id'
  has_one_attached :file
  has_one_attached :html_file
  
  def attach_html_file(content, key, filename)
    content_type = filename.ends_with?('.html') ? 'text/html' : 'application/octet-stream'
    html_file.attach(io: StringIO.new(content), key: key, filename: filename, content_type: content_type)
  end
  # def self.video_destroy
  #   # image_pathの拡張子をmp4に変換し、該当URL(S3)に存在するmp4ファイルを削除する
  #   s3 = Aws::S3::Client.new(
  #     region: ENV['AWS_REGION'],
  #     access_key_id: ENV['AWS_ACCESS_KEY_ID'],
  #     secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
  #     endpoint: ENV['AWS_ENDPOINT']
  #   )
  #   images = Image.all
  #   images.each do |image|
  #     image_path = image.image_path
  #     image_path = image_path.sub(/\.png$/, '.mp4')
  #     key = image_path.sub(/#{ENV['S3_PUBLIC_URL']}\//, '')
  #     s3.delete_object(bucket: ENV['S3_BUCKET'], key: key)
  #   end
    
end
