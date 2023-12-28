require 'open3'
require 'net/http'
require 'uri'
require 'json'

class ImageObject < ApplicationRecord
  has_many :images, foreign_key: :object_id, dependent: :destroy
  has_one_attached :ply_file, dependent: :destroy
  has_one_attached :splat_file, dependent: :destroy

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
      downloaded_ply_stream = download_from_s3(ply_key)
    rescue Aws::S3::Errors::ServiceError => e
      puts "Failed to download from S3: #{e.message}"
      raise "Failed to download from S3: #{e.message}"
    end

    # Convert ply stream to splat stream and attach it
    splat_stream = convert_ply_to_splat(downloaded_ply_stream)
    raise 'Failed to convert ply to splat' unless splat_stream

    # Attach the splat stream to Active Storage
    splat_key = "#{id}/output/a.splat"
    splat_file.attach(io: splat_stream, filename: splat_key)

    # Attach the downloaded ply file to Active Storage
    ply_file.attach(io: downloaded_ply_stream, filename: ply_key)
  end

  def create_3d
    SplatJob.perform_later(:monitor_async, self)
    req_new
  rescue StandardError => e
    Rails.logger.error "Error: #{e}"
    render json: { 'msg' => e.message }, status: :internal_server_error
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
      raise "Failed to convert ply to splat: #{error_output.read}"
    end

    # Return the splat stream
    splat_output
  end

  def download_from_s3(s3_key)
    s3 = S3ResourceService.instance.resource
    bucket_name = ENV['S3_BUCKET']

    # Download the file from S3 as a stream
    begin
      s3.bucket(bucket_name).object(s3_key).get.body
    rescue Aws::S3::Errors::ServiceError => e
      raise "Failed to download from S3: #{e.message}"
    end
  end

  def req_new
    uri = URI.parse('https://isk221492--gs-gaussian.modal.run/create/ply')
    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = 60 # 60秒後にタイムアウト
    request = Net::HTTP::Post.new(uri.request_uri, { 'Content-Type' => 'application/json' })
    request.body = { id:, id:, iterations: 3000 }.to_json

    begin
      response = http.request(request)
    rescue Net::ReadTimeout => e
      raise "Request timed out: #{e.message}"
    end
    response.body
  end
  # <-----------------------------------------------------------------for Splats
end
