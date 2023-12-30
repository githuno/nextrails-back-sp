class GyveJob < ApplicationJob
  queue_as :default

  def self.sample_method(sample_arg1, sample_arg2)
    Rails.logger.debug "GyveJob.sample_method: sample_arg1 = #{sample_arg1}, sample_arg2 = #{sample_arg2}"
  end

  def perform(method, *args)
    Rails.logger.debug "GyveJob.perform: method = #{method}"
    self.class.send(method, *args)
  end

  # 使い方（いまのところ未使用）
  # GyveJob.perform_later('sample_method', 'sample_arg1', 'sample_arg2')
end
