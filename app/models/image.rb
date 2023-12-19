class Image < ApplicationRecord
  belongs_to :object, class_name: 'ImageObject', foreign_key: 'object_id'
  has_one_attached :file
  has_one_attached :html_file

  # for Video------------------------------------------------------------------>
  VIDEO_ID_LENGTH = 36 # uuid

  def generate_presigned_url(key)
    s3 = s3_resource
    obj = s3.bucket(ENV['S3_BUCKET']).object(key)
    obj.presigned_url(:put, expires_in: 3600)
  end

  def delete_related_files
    s3 = s3_resource

    base_name = file.key.gsub(ENV['S3_PUBLIC_URL'], '').chomp(File.extname(file.key))
    return unless base_name.length == VIDEO_ID_LENGTH

    extensions = ['.html', '.mp4']
    extensions.each do |extension|
      key = "#{base_name}#{extension}"
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