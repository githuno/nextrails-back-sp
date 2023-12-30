class Gyve::V1::SplatsController < ApplicationController
  before_action :set_object, only: %i[create_splat]
  before_action -> { check_params(:user_id) }, only: %i[create_splat]

  rescue_from StandardError do |e|
    Rails.logger.error "Error: #{e}"
    render json: { 'msg' => e.message }, status: :internal_server_error # 500
  end

  def index
    # splatの一覧を返す
  end

  def show
    # splatの詳細を返す
  end

  def update
    # splatの更新を行う
  end

  def destroy
    # splatの削除を行う
  end

  def create_ply(object_id, iterations)
    # GAUSSIANにplyを作成するようにリクエスト
    g_req_create_ply(object_id, iterations)
  end

  def create_splat
    puts '>> GAUSSIAN RESPONSE HOOK is started'
    filename = request.headers['HTTP_FILENAME']
    status = params[:status]

    if File.exist?(filename)
      begin
        # Convert and upload the file to S3
        GyveJob.perform_later('convert_and_upload_async', @object, request.body.read)
        # Update the database
        @object.update(condition3d: status)

        # # Attach the ply file to Active Storage
        # ply_key = "#{id}/output/point_cloud.ply"
        # @object.plyfile.attach(io: File.open(filename), key: ply_key ,filename: filename)

        # Delete the temporary file
        File.delete(filename)
        # Request to delete the Gaussian workspace
        g_req_destroy_work(@object.id)
      rescue StandardError => e
        # If an error occurs, store it in status
        status = "8# #{e.message}"
      end
    end

    # Update the database at the end
    @object.update(condition3d: status)
  end

  private

  def convert_and_upload(object, ply_stream)
    to_splat_command = 'node lib/javascript/ply-convert-std.js - -'
    splatfile, error_output = Open3.popen3(to_splat_command) do |stdin, stdout, stderr, _wait_thr|
      Thread.new do
        IO.copy_stream(ply_stream, stdin)
        stdin.close
      end
      [stdout, stderr]
    end

    if error_output.read.present?
      puts "Failed to convert ply to splat: #{error_output.read}"
      raise "❌❌ Failed to convert ply to splat: #{error_output.read}"
    end

    # Upload the converted file to S3
    s3_key = "#{object.id}/output/a.splat"
    object.splatfile.attach(io: splatfile, key: s3_key, filename: 'a.splat')
  end

  def set_object
    @object = ImageObject.create_if_none(params)
  end

  def g_req(path, body, method)
    uri = URI.parse("https://isk221492--gs-gaussian.modal.run/#{path}")
    http = Net::HTTP.new(uri.host, uri.port) # HTTP通信を行う
    http.use_ssl = true # SSL通信を行う
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE # 証明書の検証を行わない
    http.read_timeout = 60 # 60秒後にタイムアウト

    request = if method == :post
                Net::HTTP::Post.new(uri.request_uri, { 'Content-Type' => 'application/json' })
              elsif method == :get
                Net::HTTP::Get.new(uri.request_uri, { 'Content-Type' => 'application/json' })
              end
    request.body = body.to_json

    begin
      puts '>> GAUSSIAN REQUEST is started'
      response = http.request(request)
      puts "<< GAUSSIAN RESPONSE is <<#{response.body}>>"
    rescue Net::ReadTimeout => e
      puts "❌ GAUSSIAN Request timed out: #{e.message}"
      raise "❌ GAUSSIAN Request timed out: #{e.message}"
    end
    response.read_body
  end

  def g_req_create_ply(object_id, iterations)
    g_req('create/ply', { id: object_id, iterations: }, :post)
  end

  def g_req_show_works
    g_req('show/works', {}, :get)
  end

  def g_req_destroy_work(object_id)
    g_req('del/work', { id: object_id }, :post)
  end
end
