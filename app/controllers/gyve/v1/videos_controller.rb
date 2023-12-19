class Gyve::V1::VideosController < ApplicationController
    require 'aws-sdk-s3'
    
    def pre_create
        obj = ImageObject.find_or_create_by(id: params[:object_id], user_id: params[:user_id])
        usr_id = params[:user_id]
        base_name = params[:image_path].split("/")[-1].sub(/\.mp4$/, '')
        image_path = "#{ENV['S3_PUBLIC_URL']}/#{obj.id}/#{base_name}.png"

        begin
            Image.create(object_id: obj.id, image_path: image_path, updated_by: usr_id)
            s3_key = "#{obj.id}/#{base_name}.mp4"
            presigned_url = generate_presigned_url(s3_key)
            render json: { 'msg' => 'success', 'result' => [{ 'id' => base_name, 'path' => presigned_url }] }
        rescue StandardError => e
            Rails.logger.error "Error generating presigned URL: #{e}"
            render json: { 'detail' => 'Internal Server Error' }, status: :internal_server_error
        end
    end

    def create
        image_base_path = params[:image_path].split("/")[-2..].join("/").sub(/\.mp4\?.*$/, '.png')
        image_path = "#{ENV['S3_PUBLIC_URL']}/#{image_base_path}"
        begin
            res = template_Image_and_Html_upload(image_path)
            render json: { 'msg' => 'Video uploaded successfully', 'result' => [{ 'id' => res[0], 'path' => res[1] }] }   
        rescue StandardError => e
            Rails.logger.error "Error video uploading process: #{e}"
            render json: { 'detail' => 'Internal Server Error' }, status: :internal_server_error
        end
    end
    
    private

    def template_Image_and_Html_upload(image_path)
        obj_id = image_path.split('/')[-2]
        base_name = File.basename(image_path, '.*')
        video_path = image_path.sub(/\.png$/, '.mp4')

        # image file
        png_path = Rails.root.join('public', 'template.png')
        png_template = File.read(png_path)
        png_name = "#{base_name}.png"
        png_key = "#{obj_id}/#{png_name}"
        
        # HTML file
        html_path = Rails.root.join('public', 'template.html')
        html_template = File.read(html_path)
        html_content = html_template.sub('{url}', video_path)
        html_name = "#{base_name}.html"
        html_key = "#{obj_id}/#{html_name}"
        
        image = Image.find_by(image_path: image_path)
        raise StandardError, 'Image not found' unless image

        image.file.attach(io: StringIO.new(png_template), key: png_key, filename: png_name, content_type: 'image/png')
        image.html_file.attach(io: StringIO.new(html_content), key: html_key, filename: html_name, content_type: 'text/html')
        image.save!
        return image.id, image.image_path
    end

    def generate_presigned_url(key)
        s3 = Aws::S3::Resource.new(
            region: ENV['AWS_REGION'], 
            endpoint: ENV['AWS_ENDPOINT'], 
            access_key_id: ENV['AWS_ACCESS_KEY_ID'], 
            secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
        )
        obj = s3.bucket(ENV['S3_BUCKET']).object(key)
        obj.presigned_url(:put, expires_in: 3600)
    end
end