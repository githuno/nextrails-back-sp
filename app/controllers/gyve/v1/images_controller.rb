class Gyve::V1::ImagesController < ApplicationController
  require 'base64'

  def show
    render json: { 'result' => get_images, 'msg' => 'Success' }
  rescue StandardError => e
    puts "Error: #{e}"
    render json: { 'detail' => 'get_imagesに失敗' }, status: :internal_server_error
  end

  def create
    object = ImageObject.find_by(id: params[:object_id])
    object = ImageObject.new(id: params[:object_id]) if object.nil?

    begin
      if params[:image_data]
        image_bytes = Base64.decode64(params[:image_data])
        io = StringIO.new(image_bytes)
        filename = "#{Time.now.strftime('%Y%m%d%H%M%S')}.png"
        key = "#{params[:object_id]}/#{filename}"
        image_path = "#{ENV['S3_PUBLIC_URL']}/#{key}"
        image = Image.new(object_id: object.id, image_path: image_path, updated_by: params[:user_id]) 
        image.file.attach(io: io, key: key, filename: filename, content_type: 'image/png')
        image.save!

        image_path = "#{ENV['S3_PUBLIC_URL']}/#{filename}"
        render json: { 'msg' => 'Image uploaded successfully',
                       'result' => [{ 'id' => filename, 'path' => image_path }] }
      end
    rescue StandardError => e
      puts "Error uploading image: #{e}"
      render json: { 'detail' => 'Internal Server Error' }, status: :internal_server_error
    end
  end

  private

  def get_images
    images = Image.where(object_id: params[:object_id]).order(updated_at: :desc)
    images = images.limit(params[:cnt].to_i) if params[:cnt].to_i > 0
    images.map { |image| { 'id' => File.basename(image.image_path, '.*'), 'path' => image.image_path } }
  end
end
