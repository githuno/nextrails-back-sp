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

end
