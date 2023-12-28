class Gyve::V1::ObjectsController < ApplicationController
  def index
    user_id = params[:user_id]
    ImageObject.where(created_by: user_id).each { |obj| obj.destroy if obj.images.empty? } # imageが存在しないobjectは削除
    objects = ImageObject.where(created_by: user_id).order(updated_at: :desc)
    object_info = objects.map do |obj|
      obj.info
    end
    render json: { 'msg' => 'success', 'objects' => object_info }
  rescue StandardError => e
    Rails.logger.error "Error: #{e}"
    render json: { 'msg' => e.message }, status: :internal_server_error
  end

  def destroy
    object = ImageObject.includes(:images).find(params[:object_id])

    # S3からオブジェクトを削除
    object.images.each do |image|
      image.delete_related_s3files
      image.file.purge if image.file.attached?
      # image.html_file.purge if image.html_file.attached?
    end

    # データベースからオブジェクトを削除
    object.destroy

    render json: { 'msg' => 'S3 objects and DB record deleted successfully.' }
  rescue ActiveRecord::RecordNotFound
    render json: { 'msg' => 'Error: Object not found in DB.' }, status: :not_found
  rescue StandardError => e
    Rails.logger.error "Error deleting objects from S3 and DB: #{e}"
    render json: { 'msg' => "Error deleting objects from S3 and DB: #{e}" }, status: :internal_server_error
  end
end
