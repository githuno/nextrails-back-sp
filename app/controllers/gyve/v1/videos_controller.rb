class Gyve::V1::VideosController < ApplicationController
  before_action :set_nowtime, only: %i[create pre_create]

  def pre_create
    obj = ImageObject.create_if_none(params)
    usr_id = params[:user_id]
    s3_key = "#{obj.id}/#{@now}.mp4"
    image_path = "#{ENV['S3_PUBLIC_URL']}/#{s3_key}"
    image = Image.create!(object_id: obj.id, image_path:, updated_by: usr_id)
    presigned_url = image.generate_presigned_url(s3_key)
    render json: { 'msg' => 'success', 'result' => [{ 'id' => get_basename(image_path), 'path' => presigned_url }] }
  rescue StandardError => e
    render json: { 'detail' => "Failed to pre-create video: #{e.message}" }, status: :internal_server_error
  end

  def create
    obj_id = params[:object_id]
    base_name = params[:image_path] ? get_basename(params[:image_path]) : nil
    if base_name.nil?
      render json: { 'detail' => 'image_path parameter is missing' }, status: :bad_request
      return
    end
    image_path = "#{ENV['S3_PUBLIC_URL']}/#{obj_id}/#{base_name}.mp4"
    # sample_upload(obj_id, base_name)
    render json: { 'msg' => 'Video uploaded successfully',
                   'result' => [{ 'id' => base_name, 'path' => image_path }] }
  rescue StandardError => e
    render json: { 'detail' => "Failed to upload video: #{e.message}" }, status: :internal_server_error
  end

  private

  # def sample_upload(object_id, base_name) # filenameが日付のままupするとgaussianでもDLしてしまうため削除
  #     # png file
  #     png_key = "#{object_id}/#{base_name}.png"
  #     png_template = File.read(Rails.root.join("public", "template.png"))

  #     image = Image.find_by(image_path: "#{ENV['S3_PUBLIC_URL']}/#{object_id}/#{base_name}.mp4")
  #     image.file.attach(io: StringIO.new(png_template), key: png_key, filename: "#{base_name}.png", content_type: 'image/png')
  # end

  def set_nowtime
    @now = Time.now
  end

  def log_error(e)
    Rails.logger.error "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}"
  end
end
