class GyveJob < ApplicationJob
  queue_as :default

  def self.sample_method(sample_arg1, sample_arg2)
    Rails.logger.debug "🔨 GyveJob.sample_method: sample_arg1 = #{sample_arg1}, sample_arg2 = #{sample_arg2}"
    puts "🔨 GyveJob.sample_method: sample_arg1 = #{sample_arg1}, sample_arg2 = #{sample_arg2}"
  end

  def self.tiktak(arg)
    Rails.logger.debug "🔨 GyveJob.tiktak: method = #{arg}"
    start_time = Time.now
  
    loop do
      elapsed_time = Time.now - start_time
      break if elapsed_time >= 2.minutes.to_i # 1分以上経過したらループを抜ける
      break if Redis.new.exists?("stop_tiktak") # ジョブ内に終了シグナルがないかチェック
  
      Rails.logger.debug "⌛ #{arg}: tiktak: #{elapsed_time.round}"
      print "⌛ #{arg}: tiktak: #{elapsed_time.round}\n"
      sleep 20
    end
    Redis.new.del("stop_tiktak") # ジョブが終了したら、終了シグナルをリセット
  end

  def perform(method, args)
    puts "GyveJob.perform: method = #{method}"
    Rails.logger.debug "GyveJob.perform: method = #{method}"
    self.class.send(method, *args)
  end
end