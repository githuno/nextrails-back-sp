require 'aws-sdk-s3'
class S3ResourceService
  def self.instance
    @instance ||= new
  end

  def resource
    @resource ||= Aws::S3::Resource.new(
      endpoint: ENV['AWS_ENDPOINT'],
      access_key_id: ENV['AWS_ACCESS_KEY'],
      secret_access_key: ENV['AWS_SECRET_KEY'],
      region: ENV['AWS_REGION']
    )
  end
end
