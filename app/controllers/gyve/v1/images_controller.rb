class Gyve::V1::ImagesController < ApplicationController
  before_action :set_image, only: [:destroy]

  def show
    images = Image.where(object_id: params[:object_id]).order(updated_at: :desc)
    images = images.limit(params[:cnt].to_i) if params[:cnt].to_i.positive?
    render json: { 'result' => images.map { |image| { 'id' => File.basename(image.image_path, '.*'), 'path' => image.image_path } }, 'msg' => 'Success' }
  rescue StandardError => e
    render json: { 'detail' => "get_imagesに失敗: #{e}" }, status: :internal_server_error
  end

  def create
    obj = ImageObject.find_or_create_by(id: params[:object_id], user_id: params[:user_id])

    if params[:image_data]
      image_bytes = Base64.decode64(params[:image_data])
      io = StringIO.new(image_bytes)
      filename = "#{Time.now.strftime('%Y%m%d%H%M%S')}.png"
      key = "#{obj.id}/#{filename}"
      image_path = "#{ENV['S3_PUBLIC_URL']}/#{key}"
      image = Image.new(object_id: obj.id, image_path: image_path, updated_by: params[:user_id]) 
      image.file.attach(io: io, key: key, filename: filename, content_type: 'image/png')
      image.save!

      render json: { 'msg' => 'Image uploaded successfully', 'result' => [{ 'id' => filename, 'path' => image_path }] }
    else
      render json: { 'detail' => 'No image data provided' }, status: :bad_request
    end
  rescue StandardError => e
    render json: { 'detail' => "Internal Server Error: #{e}" }, status: :internal_server_error
  end

  def destroy
    if @image
      @image.delete_related_files
      @image.file.purge
      @image.destroy
      render json: { 'msg' => 'Image deleted successfully' }
    else
      render json: { 'detail' => 'Image not found' }, status: :not_found
    end
  rescue StandardError => e
    render json: { 'detail' => "del_imageに失敗: #{e}" }, status: :internal_server_error
  end

  private

  def set_image
    @image = Image.find_by(image_path: params[:image_path])
  end
end