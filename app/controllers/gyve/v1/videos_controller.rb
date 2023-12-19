class Gyve::V1::VideosController < ApplicationController
    require 'aws-sdk-s3'
    
    def pre
        obj = ImageObject.find_or_create_by(id: params[:object_id], user_id: params[:user_id])

        begin
            s3_key = "#{obj.id}/#{params[:image_path]}"
            presigned_url = generate_presigned_url(s3_key)
            render json: { 'msg' => 'success', 'result' => [{ 'id' => '', 'path' => presigned_url }] }
        rescue StandardError => e
            Rails.logger.error "Error generating presigned URL: #{e}"
            render json: { 'detail' => 'Internal Server Error' }, status: :internal_server_error
        end
    end

    def create
        obj_id = params[:object_id] # preメソッドによってすでにテーブルは存在する
        src_name = params[:image_path]
        begin
            result = template_Image_and_Html_upload(src_name, obj_id, params[:user_id])
            render json: { 'msg' => 'Video uploaded successfully', 'result' => [{ 'id' => result[0], 'path' => result[1] }] }   
        rescue StandardError => e
            Rails.logger.error "Error video uploading process: #{e}"
            render json: { 'detail' => 'Internal Server Error' }, status: :internal_server_error
        end
    end
    
    private

    def template_Image_and_Html_upload(source_name, object_id, user_id)
        base_name = File.basename(source_name, '.*')
        source_key = "#{object_id}/#{source_name}"
        source_path = "#{ENV['S3_PUBLIC_URL']}/#{source_key}"

        # image file
        png_path = Rails.root.join('public', 'template.png')
        png_template = File.read(png_path)
        png_key = "#{object_id}/#{base_name}.png"
        png_name = "#{base_name}.png"
        # HTML file
        html_path = Rails.root.join('public', 'template.html')
        html_template = File.read(html_path)
        html_content = html_template.gsub('{url}', source_path)
        html_key = "#{object_id}/#{base_name}.html"
        html_name = "#{base_name}.html"
        
        image = Image.new(object_id: object_id, image_path: source_path, updated_by: user_id)
        image.file.attach(io: StringIO.new(png_template), key: png_key, filename: png_name, content_type: 'image/png')
        image.html_file.attach(io: StringIO.new(html_content), key: html_key, filename: html_name, content_type: 'text/html')
        image.save!
        return image.id, source_path
    end

    def generate_presigned_url(key)
        s3 = Aws::S3::Resource.new(region: ENV['AWS_REGION'])
        obj = s3.bucket(ENV['S3_BUCKET']).object(key)
        obj.presigned_url(:put, expires_in: 3600)
    end
end