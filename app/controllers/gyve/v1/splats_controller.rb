class Gyve::V1::SplatsController < ApplicationController
  def check
    # データベースから condition3d カラムの値を取得
    object = ImageObject.find_by(id: params[:object_id])
    # なければエラーを返す
    if object.nil?
        render json: { 'msg' => 'Error: Object not found in DB.' }, status: :not_found
        return
    end

    result = object.condition3d_info

    render json: { 'msg' => '',
                   'result' => { 'cdt3d_status' => result[:status], 'cdt3d_msg' => result[:message] } }
  rescue StandardError => e
    # エラーが発生した場合の処理（ログの記録等）を行う
    Rails.logger.error "Error getting condition3d from database: #{e}"
    render json: { 'msg' => 'データベースエラー' }, status: :internal_server_error
  end
end
