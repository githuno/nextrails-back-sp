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
        begin
            s3_key = "#{obj_id}/#{params[:image_path]}"
            template_Image_and_Html_upload(s3_key)
            id = params[:image_path].gsub(".mp4", "")
            image_path = "#{ENV['S3_PUBLIC_URL']}/#{s3_key.gsub(".mp4", ".png")}"
            Image.create(object_id: obj_id, image_path: image_path, updated_by: params[:user_id])
            render json: { 'msg' => 'Video uploaded successfully', 'result' => [{ 'id' => id, 'path' => image_path }] }
        rescue StandardError => e
            Rails.logger.error "Error video uploading process: #{e}"
            render json: { 'detail' => 'Internal Server Error' }, status: :internal_server_error
        end
    end
    
    private

    def template_Image_and_Html_upload(key)
        # Upload image file
        image_path = Rails.root.join('public', 'template.png')
        image_key = key.gsub(".mp4", ".png")
        
        puts("**************** image_key : #{image_key}") # DEBUG
        image = Image.new
        image.file.attach(io: File.open(image_path, 'rb'), filename: image_key, content_type: 'image/png')
        image.save!

        # Generate and upload HTML
        html_path = Rails.root.join('public', 'template.html')
        html_template = File.read(html_path)
        video_url = "https://pub-b5e3fa5caf8549b4bf8bff1ac7c7eee8.r2.dev/#{key}"
        html_content = html_template.gsub('{url}', video_url)
        html_key = key.gsub(".mp4", ".html")
        image.html_file.attach(io: StringIO.new(html_content), filename: html_key, content_type: 'text/html')
        image.save!
    end

    def generate_presigned_url(key)
        s3 = Aws::S3::Resource.new(region: ENV['AWS_REGION'])
        obj = s3.bucket(ENV['S3_BUCKET']).object(key)
        obj.presigned_url(:put, expires_in: 3600)
    end
end