class ApplicationController < ActionController::API
  protected

  def get_nowtime
    "#{Time.now.strftime('%Y%m%d%H%M%S')}"
  end

  def get_basename(url)
    url.split('/').last.sub(/\.[^.]+\z/, '')
  end
  
  def check_params(*args)
    args.each do |arg|
      params.require(arg)
    end
  end

  def tiktak(method_name)
    # 15分間、20秒ごとに秒数をRails.logger.debug
    15.times do |i|
      break if @stop_tiktak # 終了フラグが立っていたらループを抜ける
      Rails.logger.debug "⌛ #{method_name}: tiktak: #{i * 20}"
      sleep 20
    end
    @stop_tiktak = false # ループが終わったらフラグをリセット
  end
  def stop_tiktak
    Rails.logger.debug 'GyveJob.tiktak stoped'
    @stop_tiktak = true
  end

end
