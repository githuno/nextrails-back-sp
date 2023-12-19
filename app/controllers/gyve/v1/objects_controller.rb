class Gyve::V1::ObjectsController < ApplicationController
    def index
      user_id = params[:user_id]
      objects = ImageObject.where(created_by: user_id)
      object_info = objects.map do |obj|
        {
          "created_by": user_id,
          "id": obj.id,
          "name": obj.name,
          "description": obj.description,
          "created_at": obj.created_at,
          "updated_at": obj.updated_at,
          "main_image": obj.main_image,
          "cdt3d_status": obj.condition3d_info[:status],
          "cdt3d_msg": obj.condition3d_info[:message]
        }
      end
      render json: { 'msg' => 'success', 'objects' => object_info }
    rescue StandardError => e
      Rails.logger.error "Error: #{e}"
      render json: { 'msg' => 'error' }, status: :internal_server_error
    end

    def destroy
      begin
        object = ImageObject.find(params[:object_id])
  
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
      rescue => e
        Rails.logger.error "Error deleting objects from S3 and DB: #{e}"
        render json: { 'msg' => "Error deleting objects from S3 and DB: #{e}" }, status: :internal_server_error
      end
    end
end