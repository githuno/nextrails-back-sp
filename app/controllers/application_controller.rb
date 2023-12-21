class ApplicationController < ActionController::API
  protected

  def set_nowtime
    @now = "#{Time.now.strftime('%Y%m%d%H%M%S')}"
  end

  def get_basename(url)
    url.split('/').last.sub(/\.[^.]+\z/, '')
  end
end
