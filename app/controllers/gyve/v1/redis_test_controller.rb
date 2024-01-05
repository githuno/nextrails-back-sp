class Gyve::V1::RedisTestController < ApplicationController

    def test
        # tiktakジョブのテスト
        # workerを同時起動（bundle exec sidekiq -q default）する必要がある。
        
        GyveJob.perform_later('tiktak', 'tiktak_test')

        sleep 60
        Redis.new.set("stop_tiktak", 1) # 引数'1'はは特に意味を持つわけではなく、単にキーstop_tiktakが存在することを示すための値
        # ※ Redis.new.set("stop_tiktak", true) としても、Redis.new.exists?("stop_tiktak") は true を返す
        # ※ Redis.new.set("stop_tiktak", false) としても、Redis.new.exists?("stop_tiktak") は true を返す
        # ※ Redis.new.set(key, value)メソッドを参照

        # tiktakが終了するまで待機される
        GyveJob.perform_later('sample_method', ['Enable_arg1', 'Enable_arg2'])
        render json: { 'msg' => 'リクエストを受け付けました。' }

    end
end
