class Gyve::V1::ImagesController < ApplicationController
  before_action :set_image, only: [:destroy]
  before_action :set_nowtime, only: [:create]

  def show
    images = Image.where(object_id: params[:object_id]).order(updated_at: :desc)
    images = images.limit(params[:image_cnt].to_i) if params[:image_cnt].present? && params[:image_cnt].to_i.positive?
    render json: { 'result' => images.map do |image|
                                 { 'id' => File.basename(image.image_path, '.*'), 'path' => image.image_path }
                               end, 'msg' => 'Success' }
  rescue StandardError => e
    render json: { 'detail' => "get_imagesに失敗: #{e.message}" }, status: :internal_server_error
  end

  def create
    obj = ImageObject.create_if_none(params)

    if params[:image_data]
      image = Image.upload_image(obj, params[:image_data], params[:user_id], @now)
      render json: { 'msg' => 'Image uploaded successfully',
                     'result' => [{ 'id' => image.id, 'path' => image.image_path }] }
    else
      render json: { 'detail' => 'No image data provided' }, status: :bad_request
    end
  rescue StandardError => e
    render json: { 'detail' => "Image upload failed: #{e.message}" }, status: :internal_server_error
  end

  def destroy
    if @image
      @image.delete_related_s3files
      @image.file.purge
      @image.destroy
      render json: { 'msg' => 'Image deleted successfully' }
    else
      render json: { 'detail' => 'Image not found' }, status: :not_found
    end
  rescue StandardError => e
    render json: { 'detail' => "Image deletion failed: #{e.message}" }, status: :internal_server_error
  end

  private

  def set_image
    @image = Image.find_by(image_path: params[:image_path])
  end

  def set_nowtime
    @now = Time.now
  end
end
