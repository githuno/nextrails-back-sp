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

  def generate_thumbnail
    s3 = s3_resource
    s3_bucket = ENV['S3_BUCKET']
    s3_folder = "#{self.image_path.split('/')[-2]}"
    basename = "#{self.id}"
    thumbnail = Tempfile.new([basename, '.png'], Rails.root.join('public', 'tmp'))
    key = "#{s3_folder}/#{basename}.mp4"
  
    begin
      # Download the MP4 file from S3 to a local temporary file
      s3.get_object({ bucket: s3_bucket, key: key, response_target: thumbnail.path })
  
      # Generate thumbnail using FFmpeg
      system "ffmpeg -i #{tempfile.path} -ss 00:00:01 -s 300x300 -vframes 1 -y #{tempfile.path}"
      # 作成した画像と、template.pngを合成する
      system "composite -gravity center #{Rails.root.join('public', 'template.png')} #{tempfile.path} #{tempfile.path}"
  
      # Attach the generated thumbnail to the Image object
      file.attach(io: File.open(tempfile.path), filename: "#{thumbnail}.png", content_type: 'image/png')
    rescue StandardError => e
      Rails.logger.error "Error generating thumbnail: #{e}"
    ensure
      # Clean up the temporary file
      tempfile.close
      tempfile.unlink
    end
  end

  def delete_related_s3files
    s3 = s3_resource

    obj_id = self.object_id
    base_name = self.image_path.split('/').last.sub(/.[^.]+\z/, '')
    return unless base_name.length == VIDEO_ID_LENGTH

    extensions = ['.html', '.mp4']
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