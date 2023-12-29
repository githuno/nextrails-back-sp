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

  def self.upload_image(obj, image_data, user_id, now)
    image_bytes = Base64.decode64(image_data)
    io = StringIO.new(image_bytes)
    filename = "#{now}.png"
    key = "#{obj.id}/#{filename}"
    image_path = "#{ENV['S3_PUBLIC_URL']}/#{key}"
    image = Image.create!(object_id: obj.id, image_path:, updated_by: user_id)
    image.file.attach(io:, key:, filename:, content_type: 'image/png')
    image
  rescue StandardError => e
    raise "Failed to upload image: #{e.message}"
  end

  def delete_related_s3files
    obj_id = id
    base_name = image_path.split('/').last.sub(/\.[^.]+\z/, '')
    return if File.extname(image_path) == '.png'

    extensions = ['.png', '.html', '.mp4'] # 削除対象の拡張子
    extensions.each do |extension|
      key = "#{obj_id}/#{base_name}#{extension}"
      S3ResourceService.instance.resource.bucket(ENV['S3_BUCKET']).object(key).delete
    end
  rescue Aws::S3::Errors::ServiceError => e
    raise "Failed to delete related S3 files: #{e.message}"
  end

  def main_image
    images.first&.image_path || ''
  end

  # for Splats----------------------------------------------------------------->
  def info
    if ply_file.attached? && !splat_file.attached?
      # バックグラウンドでattach_splatおよびDBのupdateを実行する
      SplatJob.perform_later(:convert_async, self)
    end
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

  def attach_splat
    ply_key = "#{id}/output/cloud_ponit.ply"
    # Download the ply file from S3 as a stream
    begin
      puts '>> ATTACH : download process start...' 
      downloaded_ply_stream = download_from_s3(ply_key)
      puts '>> ATTACH : download process finished !!'
    rescue Aws::S3::Errors::ServiceError => e
      puts "Failed to download from S3: #{e.message}"
      raise "❌❌ Failed to download from S3: #{e.message}"
    end

    # Convert ply stream to splat stream and attach it
    puts '>> ATTACH : convert process start...'
    splat_stream = convert_ply_to_splat(downloaded_ply_stream)
    raise '❌❌ Failed to convert ply to splat' unless splat_stream
    puts '>> ATTACH : convert process finished !!'

    # Attach the splat stream to Active Storage
    splat_key = "#{id}/output/a.splat"
    splat_file.attach(io: splat_stream, filename: splat_key)

    # Attach the downloaded ply file to Active Storage
    ply_file.attach(io: downloaded_ply_stream, filename: ply_key)
    puts '>> ATTACH : attach process finished !!'
  end

  def create_3d
    attach_splat # debug
    # SplatJob.perform_later(:monitor_async, self)
    # req_new
  rescue StandardError => e
    Rails.logger.error "Failed to create 3d: #{e.message}"
    raise "Failed to create 3d: #{e.message}"
  end

  private

  def convert_ply_to_splat(ply_stream)
    # Convert ply stream to splat stream
    to_splat_command = 'node lib/javascript/ply_convert.js - -'
    splat_output, error_output = Open3.popen3(to_splat_command) do |stdin, stdout, stderr, _wait_thr|
      Thread.new do
        IO.copy_stream(ply_stream, stdin)
        stdin.close
      end
      [stdout, stderr]
    end

    if error_output.read.present?
      puts "Failed to convert ply to splat: #{error_output.read}"
      raise "❌❌ Failed to convert ply to splat: #{error_output.read}"
    end

    # Return the splat stream
    splat_output
  end

  def download_from_s3(s3_key)
    s3 = S3ResourceService.instance.resource
    bucket_name = ENV['S3_BUCKET']

    # Download the file from S3 as a stream
    begin
      puts '>> Downloading ply file from S3.......'
      s3.bucket(bucket_name).object(s3_key).get.body
    rescue Aws::S3::Errors::ServiceError => e
      raise "❌❌ Failed to download from S3: #{e.message}"
    end
  end

  def req_new
    uri = URI.parse('https://isk221492--gs-gaussian.modal.run/create/ply')
    http = Net::HTTP.new(uri.host, uri.port) # HTTP通信を行う
    http.use_ssl = true # SSL通信を行う
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE # 証明書の検証を行わない
    http.read_timeout = 60 # 60秒後にタイムアウト
    request = Net::HTTP::Post.new(uri.request_uri, { 'Content-Type' => 'application/json' })
    request.body = { created_by:, id:, iterations: 3000 }.to_json

    begin
      puts '>> GAUSSIAN REQUEST is started'
      response = http.request(request)
      puts "<< GAUSSIAN REQUEST is finished: response is <<#{response.body}>>"
    rescue Net::ReadTimeout => e
      puts "Rails > GAUSSIAN Request timed out: #{e.message}"
      raise "Rails > GAUSSIAN Request timed out: #{e.message}"
    end
    response.read_body
  end
  # <-----------------------------------------------------------------for Splats
end
