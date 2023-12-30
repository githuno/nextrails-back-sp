class GyveJob < ApplicationJob
  queue_as :default

  @@stop_tiktak = false

  def self.sample_method(sample_arg1, sample_arg2)
    Rails.logger.debug "GyveJob.sample_method: sample_arg1 = #{sample_arg1}, sample_arg2 = #{sample_arg2}"
  end

  def self.tiktak(arg)
    Rails.logger.debug "GyveJob.tiktak: method = #{arg}"
    # 3分間、20秒ごとに秒数をRails.logger.debug
    3.times do |i|
      break if @@stop_tiktak # 終了フラグが立っていたらループを抜ける
      Rails.logger.debug "⌛ #{arg}: tiktak: #{i * 20}"
      sleep 20
    end
    @@stop_tiktak = false # ループが終わったらフラグをリセット
  end

  def perform(method, *args)
    puts "GyveJob.perform: method = #{method}"
    Rails.logger.debug "GyveJob.perform: method = #{method}"
    self.class.send(method, *args)
  end

  # 使い方（いまのところ未使用）
  # GyveJob.perform_later('sample_method', 'sample_arg1', 'sample_arg2')
end