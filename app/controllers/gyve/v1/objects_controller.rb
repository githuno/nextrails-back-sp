class Gyve::V1::ObjectsController < ApplicationController
  before_action :set_object, only: [:destroy, :create_3d]
  before_action -> { check_params(:user_id) }, only: [:index, :destroy, :create_3d]

  rescue_from StandardError do |e|
    Rails.logger.error "Error: #{e}"
    render json: { 'msg' => e.message }, status: :internal_server_error
  end

  def index
    user_id = params[:user_id]
    ImageObject.where(created_by: user_id).each { |obj| obj.destroy if obj.images.empty? } # imageが存在しないobjectは削除
    objects = ImageObject.where(created_by: user_id).order(updated_at: :desc)
    object_info = objects.map do |obj|
      obj.info
    end
    render json: { 'msg' => 'success', 'objects' => object_info }
  end

  def destroy
    @object.images.each do |image|
      image.delete # image.delete関数内でobjectの削除も行う
    end
    render json: { 'msg' => 'S3 objects and DB record deleted successfully.' }
  end

  def create_3d
    iterations = 3000
    # splatsモデルは現状未作成のため、splatsコントローラーを呼び出す
    @splats = Gyve::V1::SplatsController.new
    @splats.create_ply(@object.id, iterations)
    render json: { 'msg' => '0# 作成リクエストを受け付けました。' }
  end

  private

  def set_object
    @object = ImageObject.create_if_none(params)
  end
end
