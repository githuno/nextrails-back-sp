class Gyve::V1::VideosController < ApplicationController
  before_action :set_nowtime, only: %i[create pre_create]
  before_action :set_s3, only: %i[create pre_create]
  before_action :set_object, only: %i[create pre_create]
  before_action -> { check_params(:user_id, :object_id) }, only: %i[create pre_create]
  before_action -> { check_params(:image_path) }, only: :create

  rescue_from StandardError do |e|
    render json: { 'detail' => e.message }, status: :internal_server_error # 500
  end

  def pre_create
    s3_key = "#{@object.id}/#{@now}.mp4"
    presigned_url = @s3.object(s3_key).presigned_url(:post)
    render json: { 'msg' => 'success', 'result' => [{ 'id' => @now, 'path' => presigned_url }] }
  end

  def create
    # raise 'Invalid file extension.' unless params[:image_path].end_with?('.mp4') # 拡張子がmp4でなければエラーを返す
    base_name = get_basename(params[:image_path]) # (ApplicationController)
    image_path = "#{ENV['S3_PUBLIC_URL']}/#{@object.id}/#{base_name}.mp4"
    @image = Image.create!(object_id: @object.id, image_path: image_path, updated_by: params[:user_id])
    render json: { 'msg' => 'Video uploaded successfully', 'result' => [{ 'id' => base_name, 'path' => image_path }] }
  end

  def thumbnail_create
    # # videoを受け取る（HTTP）
    # # ・・・
    # # サムネイルを作成する
    # thumbnail = create_thumbnail(video)
    # # サムネイルをS3にアップロードする
    # @image.file.attach(io: thumbnail, key: key, filename: filename, content_type: 'image/png')
    # # DBに登録する
    # Thumbnail.create!(object_id: @object.id, thumbnail_path: thumbnail.path, updated_by: params[:user_id])
    # render json: { 'msg' => 'Thumbnail created successfully.' }
  end

  private

  def set_nowtime
    @now = get_nowtime # (ApplicationController)
  end

  def set_s3
    @s3 = S3ResourceService.instance.resource
  end

  def set_object
    @object = ImageObject.create_if_none(params)
  end
end