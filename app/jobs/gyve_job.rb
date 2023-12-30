# app/jobs/gyve_job.rb
class GyveJob < ApplicationJob
  queue_as :default

  def self.tiktak(method_name)
    # 20秒ごとに秒数をputs
    20.times do |i|
      puts "⌛ #{method_name}: tiktak: #{i}"
      sleep 1
    end
  end

  def self.convert_and_upload_async(object, ply_stream)
    # 非同期でconvert終了まで 20秒ごとに秒数をputs
    tiktak_thread = Thread.new { tiktak('convert_and_upload_async') }

    # Splatsコントローラのconvert_and_upload(object, ply_stream)にそのまま渡す
    SplatsController.convert_and_upload(object, ply_stream)

    # Ensure tiktak thread is killed when convert_and_upload is done
    tiktak_thread.kill
  end

  def perform(method, *args)
    puts "GyveJob.perform: method = #{method}"
    self.class.send(method, *args)
  end
end