require 'aws-sdk-s3'

class S3ResourceService
  DELETE_TARGET_EXTENSIONS = ['.png', '.html', '.mp4'].freeze

  def self.instance
    @instance ||= new
  end

  def resource
    @resource ||= Aws::S3::Resource.new(
      endpoint: ENV.fetch('AWS_ENDPOINT'),
      access_key_id: ENV.fetch('AWS_ACCESS_KEY'),
      secret_access_key: ENV.fetch('AWS_SECRET_KEY'),
      region: ENV.fetch('AWS_REGION')
    ).bucket(ENV.fetch('S3_BUCKET'))
  end

  def presigned_url(key, method)
    resource.object(key).presigned_url(method, expires_in: 3600)
  rescue Aws::S3::Errors::ServiceError => e
    raise "Failed to generate presigned URL: #{e.message}"
  end

  def delete_related(image)
    return if File.extname(image.image_path) == '.png'

    DELETE_TARGET_EXTENSIONS.each do |extension|
      key = "#{image.object_id}/#{image.basename}#{extension}"
      resource.object(key).delete
    end
  rescue Aws::S3::Errors::ServiceError => e
    raise "Failed to delete related S3 files: #{e.message}"
  end
end