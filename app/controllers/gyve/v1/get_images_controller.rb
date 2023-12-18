class Gyve::V1::GetImagesController < ApplicationController
  def image
    object_id = params[:object_id]
    cnt = params[:cnt].to_i

    begin
      image_paths = get_images_by_object_id(object_id, cnt)
      result = image_paths.map do |path|
        { 'id' => File.basename(path, '.*'), 'path' => path }
      end
      render json: { 'result' => result, 'msg' => 'Success' }
    rescue StandardError => e
      puts "Error: #{e}"
      render json: { 'detail' => 'get_imagesに失敗' }, status: :internal_server_error
    end
  end

  private

  def get_images_by_object_id(object_id, cnt)
    begin
      image_paths = Image.fetch_images(object_id, cnt)
    rescue => e
      puts "Error: #{e}"
      nil
    end
  end
end
