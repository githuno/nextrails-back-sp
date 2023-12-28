# app/jobs/splat_job.rb
class SplatJob < ApplicationJob
  queue_as :default

  def self.convert_async(image_object)
    image_object.attach_splat
    image_object.update(condition3d: "10# #{ENV['S3_PUBLIC_URL']}/#{image_object.id}/output/a.splat")
  end

  def self.monitor_async(image_object)
    initial_condition3d = image_object.condition3d
    puts "monitoriing condition3d: initial = #{initial_condition3d}"

    15.times do |i|
      puts "monitoriing condition3d: times = #{i}"
      image_object.reload # 最新の状態を読み込む
      if image_object.condition3d != initial_condition3d
        puts "condition3d has changed: #{image_object.condition3d}"
        image_object.attach_splat
        image_object.update(condition3d: "10# #{ENV['S3_PUBLIC_URL']}/#{image_object.id}/output/a.splat")
        break
      end
      sleep 60 # 1分待つ
    end
  end

  def perform(method, *args)
    self.class.send(method, *args)
  end
end