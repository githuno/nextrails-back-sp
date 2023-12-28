class Gyve::V1::SplatsController < ApplicationController
  before_action :set_object, only: %i[create pre_create]

  def check_works
    # workspaceのフォルダを確認
  end

  def destroy_works
    # workspaceのフォルダを削除
  end

  def create
    msg = @object.create_3d
    render json: { 'msg' => msg }
  rescue StandardError => e
    render json: { 'error' => e.message }, status: :internal_server_error
  end

  def update; end

  def destroy; end

  private

  def set_object
    @object = ImageObject.find_or_create_by(id: params[:object_id], name: params[:object_id], created_by: params[:user_id])
  end
end
