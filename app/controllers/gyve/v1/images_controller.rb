class Gyve::V1::ImagesController < ApplicationController
  before_action :set_image, only: [:destroy]
  before_action :set_nowtime, only: [:create]
  before_action -> { check_params(:object_id) }, only: [:show]
  before_action -> { check_params(:user_id, :object_id, :image_data) }, only: [:create]
  before_action -> { check_params(:image_path) }, only: [:destroy]

  def show
    images = Image.where(object_id: params[:object_id]).order(updated_at: :desc)
    images = images.limit(params[:image_cnt].to_i) if params[:image_cnt].present? && params[:image_cnt].to_i.positive?
    render json: { 'result' => images.map { |image| { 'id' => image.id, 'path' => image.image_path } }, 'msg' => 'Success' }
  end

  def create
    obj = ImageObject.create_if_none(params.permit(:user_id, :object_id, :image_data))
    image = Image.upload(obj.id, params[:user_id], params[:image_data], @now)
    render json: { 'msg' => 'Image uploaded successfully', 'result' => [{ 'id' => image.id, 'path' => image.image_path }] }
  end

  def destroy
    @image.delete
    render json: { 'msg' => 'Image deleted successfully' }
  end

  private

  def set_image
    @image = Image.find_by!(image_path: params[:image_path])
  end

  def set_nowtime
    @now = get_nowtime
  end
end