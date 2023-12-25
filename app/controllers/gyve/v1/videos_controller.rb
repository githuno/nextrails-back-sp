class Gyve::V1::VideosController < ApplicationController
    before_action :set_nowtime, only: [:create, :pre_create]

    def pre_create
        obj = ImageObject.find_or_create_by(id: params[:object_id], user_id: params[:user_id])
        usr_id = params[:user_id]
        s3_key = "#{obj.id}/#{@now}.mp4"
        image_path = "#{ENV['S3_PUBLIC_URL']}/#{s3_key}"

        begin
            image = Image.create(object_id: obj.id, image_path: image_path, updated_by: usr_id)
            presigned_url = image.generate_presigned_url(s3_key)
            render json: { 'msg' => 'success', 'result' => [{ 'id' => get_basename(image_path), 'path' => presigned_url }] }
        rescue StandardError => e
            log_error(e)
            render json: { 'detail' => 'Internal Server Error' }, status: :internal_server_error
        end
    end

    def create
        obj_id = params[:object_id]
        base_name = params[:image_path] ? get_basename(params[:image_path]) : nil
        if base_name.nil?
            render json: { 'detail' => 'image_path parameter is missing' }, status: :bad_request
            return
        end
        image_path = "#{ENV['S3_PUBLIC_URL']}/#{obj_id}/#{base_name}.mp4"
        begin
            # sample_upload(obj_id, base_name)
            render json: { 'msg' => 'Video uploaded successfully', 'result' => [{ 'id' => base_name, 'path' => image_path }] }   
        rescue StandardError => e
            log_error(e)
            render json: { 'detail' => 'Internal Server Error' }, status: :internal_server_error
        end
    end
    
    private

    # def sample_upload(object_id, base_name) # filenameが日付のままupするとgaussianでもDLしてしまうため削除
    #     # png file
    #     png_key = "#{object_id}/#{base_name}.png"
    #     png_template = File.read(Rails.root.join("public", "template.png"))
        
    #     image = Image.find_by(image_path: "#{ENV['S3_PUBLIC_URL']}/#{object_id}/#{base_name}.mp4")
    #     image.file.attach(io: StringIO.new(png_template), key: png_key, filename: "#{base_name}.png", content_type: 'image/png')
    # end

    def log_error(e)
        Rails.logger.error "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}"
    end
end