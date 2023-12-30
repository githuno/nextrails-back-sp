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

  def create_ply(object_id, iterations)
    g_req_create_ply(object_id, iterations)
  end

  def create_splat
    puts '>> GAUSSIAN RESPONSE HOOK is started'
    Rails.logger.debug '>> GAUSSIAN RESPONSE HOOK is started'
    # GyveJob.perform_later('tiktak', 'create_splat') # Threadsが非推奨のため、後で検証する
    # puts '>> GyveJob is working... log/development.logを確認してください'
    # Procfileでworkerを同時起動（bundle exec sidekiq -q default）する必要がある。
    # また、upstashへのコマンドリクエストが大量発生しており、検証が必要。
    
    status = request.headers['HTTP_PLY_STATUS']
    puts "status is #{status}" # DEBUG
    obj_id = request.headers['HTTP_PLY_ID']
    # obj_id = request.headers['HTTP_PLY_ID'].tr('"', '')
    puts "obj_id is #{obj_id}" # DEBUG
    file = params[:file]
    @object = ImageObject.find_by(id: obj_id)
    puts "2: object is #{@object}" # DEBUG
    dir_path = "#{Rails.root}/tmp/#{obj_id}"
    FileUtils.mkdir_p(dir_path) unless Dir.exist?(dir_path)
    plyfile = "#{dir_path}/point_cloud.ply"

    # # DEBUG-------------------------------------------------------------------
    # Rails.logger.debug '>> DEBUG: Using local file instead of request body'
    # plyfile = "#{dir_path}/63fd89ec-3052-4079-a6cb-e626a121218f/output/point_cloud.ply"
    # Rails.logger.debug ">> DEBUG: plyfile = #{plyfile}"
    # # DEBUG-------------------------------------------------------------------
    
    if file.present?
      begin
        puts ">> DEBUG: Writing #{plyfile}"
        tiktak_thread = Thread.new { tiktak('write') } # (ApplicationController)
        puts ">> DEBUG: tiktak_thread is #{tiktak_thread}"
        File.open(plyfile, 'wb') do |f|
          f.write(file.read)
          puts ">> DEBUG: Wrote #{plyfile}"
        end
        tiktak_thread.kill
        Thread.new do
          convert_and_upload(@object, plyfile)
        end
      rescue StandardError => e
        status = "9# #{e.message}"
      end
    end

    # Update the database at the end
    puts ">> DEBUG: Updating condition3d to #{status}" # DEBUG
    Rails.logger.debug ">> DEBUG: Updating condition3d to #{status}" # DEBUG
    @object.update!(condition3d: status)
    render json: { 'msg' => 'splat is creating...' }, status: :ok # 200
  end

  private

  def convert_and_upload(object, ply_path)
    tiktak_thread = Thread.new { tiktak('convert_and_upload') } # (ApplicationController)
    splat_path = "#{Rails.root}/tmp/#{object.id}/a.splat"
    to_splat_command = "node #{Rails.root}/lib/javascript/ply-convert-std.js #{ply_path} #{splat_path} > /dev/null"
    system(to_splat_command)
  
    # Attach the splat file to Active Storage
    splat_key = "#{object.id}/output/a.splat"
    object.splat_file.attach(io: File.open(splat_path), key: splat_key, filename: 'a.splat')

    # # Attach the ply file to Active Storage
    # ply_key = "#{object.id}/output/point_cloud.ply"
    # @object.plyfile.attach(io: File.open(ply_path), key: ply_key ,filename: 'point_cloud.ply')

    # # Delete the directory
    FileUtils.rm_rf("#{Rails.root}/tmp/#{object.id}")

    # Request to delete the Gaussian workspace
    g_req_destroy_work(object.id)

    # Update the database
    object.update(condition3d: "10# #{ENV['S3_PUBLIC_URL']}/#{object_id}/output/a.splat")

    # Ensure tiktak thread is killed when convert_and_upload is done
    tiktak_thread.kill
    Rails.logger.debug "🎉🎉🎉 Succeeded to convert ply to splat"
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
    rescue Net::ReadTimeout => e
      Rails.logger.debug "❌ GAUSSIAN REQUEST <#{method}> timed out: #{e.message}"
      raise "❌ GAUSSIAN REQUEST <#{method}> timed out: #{e.message}"
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
