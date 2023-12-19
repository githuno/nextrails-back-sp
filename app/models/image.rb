class Image < ApplicationRecord
  belongs_to :object, class_name: 'ImageObject', foreign_key: 'object_id'
  has_one_attached :file
  has_one_attached :html_file
  
  
  def delete_related_files
    s3 = Aws::S3::Resource.new(
      region: ENV['AWS_REGION'],
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
      endpoint: ENV['AWS_ENDPOINT']
    )
  
    base_name = self.image_path.gsub(ENV['S3_PUBLIC_URL'], '').chomp(File.extname(self.image_path))
    if base_name.length == 36
      extensions = [".html", ".mp4"]
      extensions.each do |extension|
        key = "#{base_name}#{extension}"
        s3.bucket(ENV['S3_BUCKET']).object(key).delete
      end
    end
  end
end
