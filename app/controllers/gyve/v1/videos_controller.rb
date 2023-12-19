class Gyve::V1::VideosController < ApplicationController
    before_action :set_base_name, only: [:create, :pre_create]

    def pre_create
        obj = ImageObject.find_or_create_by(id: params[:object_id], user_id: params[:user_id])
        usr_id = params[:user_id]
        image_path = "#{ENV['S3_PUBLIC_URL']}/#{obj.id}/#{@base_name}.png"

        begin
            image = Image.create(object_id: obj.id, image_path: image_path, updated_by: usr_id)
            s3_key = "#{obj.id}/#{@base_name}.mp4"
            presigned_url = image.generate_presigned_url(s3_key)
            render json: { 'msg' => 'success', 'result' => [{ 'id' => @base_name, 'path' => presigned_url }] }
        rescue StandardError => e
            log_error(e)
            render json: { 'detail' => 'Internal Server Error' }, status: :internal_server_error
        end
    end

    def create
        obj_id = params[:object_id]
        image_path = "#{ENV['S3_PUBLIC_URL']}/#{obj_id}/#{@base_name}.png"
        begin
            sample_upload(image_path)
            render json: { 'msg' => 'Video uploaded successfully', 'result' => [{ 'id' => @base_name, 'path' => image_path }] }   
        rescue StandardError => e
            log_error(e)
            render json: { 'detail' => 'Internal Server Error' }, status: :internal_server_error
        end
    end
    
    private

    def set_base_name
        @base_name = params[:image_path].split('/').last.sub(/\.[^.]+\z/, '')
    end

    def sample_upload(image_path)
        obj_id = image_path.split('/')[-2]
        # png file
        png_name = "#{@base_name}.png"
        png_key = "#{obj_id}/#{png_name}"
        png_template = File.read(Rails.root.join("public", "template.png"))
        
        image = Image.find_by(image_path: image_path)
        image.file.attach(io: StringIO.new(png_template), key: png_key, filename: png_name, content_type: 'image/png')
    end

    def log_error(e)
        Rails.logger.error "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}"
    end
end