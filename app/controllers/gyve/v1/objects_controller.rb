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
end