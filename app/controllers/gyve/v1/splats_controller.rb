class Gyve::V1::SplatsController < ApplicationController
  before_action -> { check_params(:user_id) }, only: %i[create_ply]

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

  def create_ply(object_id, iterations) # 別のコントローラーから呼び出す
    Thread.new do # 元のスレッドとは異なるコンテキストで実行されるため、@_responseなどのインスタンス変数が初期化されていない可能性がある
      g_req_create_ply(object_id, iterations)
      puts '【🔨 Splats_ctrl -> GAUSSIAN】0# 作成リクエストを受け付けました。' # DEBUG
    end
    return
    # render json: { 'msg' => '【Splats】0# 作成リクエストを受け付けました。' }
  end

  def create_splat
    puts '🔨🔨 GAUSSIAN RESPONSE HOOK is started'
    Rails.logger.debug '>> GAUSSIAN RESPONSE HOOK is started'
    # GyveJob.perform_later('tiktak', 'create_splat') # Threadsが非推奨のため、後で検証する
    # puts '>> GyveJob is working... log/development.logを確認してください'
    # Procfileでworkerを同時起動（bundle exec sidekiq -q default）する必要がある。
    # また、upstashへのコマンドリクエストが大量発生しており、検証が必要。

    status = request.headers['HTTP_PLY_STATUS']
    obj_id = request.headers['HTTP_PLY_ID']
    file = params[:file]

    # # CURL でのリクエスト方法----------------------------------------------------
    # curl --request POST \
    # --url https://refurnish.onrender.com/gyve/v1/return_ply \
    # --header 'PLY_ID: 63fd89ec-3052-4079-a6cb-e626a121218f' \
    # --header 'PLY_STATUS: text' \ # ✘ 'PLY_STATUS: "text"'
    # -F 'file=@./point_cloud.ply' # ✘ --data "file: './point_cloud.ply'"
    # # --------------------------------------------------------------------------

    @object = ImageObject.find_by(id: obj_id)
    @dir_path = "#{Rails.root}/tmp/#{obj_id}"
    FileUtils.mkdir_p(@dir_path) unless Dir.exist?(@dir_path)

    if file.present?
      tiktak_thread = Thread.new { tiktak('convert') } # (ApplicationController)
      thread_result = Thread.new do
        convert_and_upload(@object, file.tempfile)
        '10# SPLAT-Conversion and upload successful'
      rescue StandardError => e
        "9# #{e.message}"
      end
      tiktak_thread.kill
      status = thread_result.value
    end

    puts ">> DEBUG: status is #{status}" # DEBUG
    # Update the database temporarily
    @object.update!(condition3d: status)
    # Render temporarily
    puts '🎉🎉🎉 Succeeded to convert ply to splat'
    render json: { 'msg' => 'THREAD convert is creating...' }, status: :ok # 200
  end

  private

  def convert_and_upload(object, ply_stream)
    splat_path = "#{Rails.root}/tmp/#{object.id}/a.splat"
    Open3.popen3("node #{Rails.root}/lib/javascript/ply-convert-std.js - #{splat_path} > /dev/null") do |stdin, _stdout, _stderr, _wait_thr|
      IO.copy_stream(ply_stream, stdin)
      stdin.close
      # Handle stdout and stderr if necessary
    end

    # Attach the splat file to Active Storage
    splat_key = "#{object.id}/output/a.splat"
    object.splat_file.attach(io: File.open(splat_path), key: splat_key, filename: 'a.splat')
    puts '>> DEBUG: Attached splat file to Active Storage' # DEBUG

    # Delete the directory
    FileUtils.rm_rf("#{Rails.root}/tmp/#{object.id}")
    puts ">> DEBUG: Deleted #{Rails.root}/tmp/#{object.id}" # DEBUG

    # Request to delete the Gaussian workspace
    g_req_destroy_work(object.id)
    puts '>> DEBUG: Requested to delete the Gaussian workspace' # DEBUG

    # Update the database
    object.update(condition3d: "10# #{ENV['S3_PUBLIC_URL']}/#{object.id}/output/a.splat")
    puts ">> DEBUG: Updated condition3d to #{ENV['S3_PUBLIC_URL']}/#{object.id}/output/a.splat" # DEBUG

    # Ensure the splat file is attached
    puts '🎉🎉🎉 Succeeded to convert ply to splat'
    Rails.logger.debug '🎉🎉🎉 Succeeded to convert ply to splat'
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
      Rails.logger.debug ">> GAUSSIAN REQUEST <#{method}> is started"
      response = http.request(request)
      Rails.logger.debug "<< GAUSSIAN RESPONSE <#{method}> is <<#{response.body}>>"
      response.read_body
    rescue Net::ReadTimeout => e
      Rails.logger.debug "❌ GAUSSIAN REQUEST <#{method}> timed out: #{e.message}"
    end
  end

  def g_req_create_ply(object_id, iterations)
    g_req('create/ply', { id: object_id, iterations: iterations}, :post)
  end

  def g_req_show_works
    g_req('show/works', {}, :get)
  end

  def g_req_destroy_work(object_id)
    g_req('del/work', { id: object_id }, :post)
  end
end
