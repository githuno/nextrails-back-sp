require 'open3'

class TailscaleController < ApplicationController
    def up
        unless File.exist?("#{Rails.root}/tmp/tailscale.txt")
            puts ">> tailscale up --ssh(initialize)" # 初回のみ実行
            pid = Process.spawn("tailscale up --ssh --hostname=#{ENV['SERVER_NAME']} > #{Rails.root}/tmp/tailscale.txt 2>&1 &")
            Process.detach(pid) # プロセスをデタッチしてバックグラウンドで実行
            sleep 3 # コマンドの出力を待つための小さな遅延
            output = File.read("#{Rails.root}/tmp/tailscale.txt")
            render plain: output
        else
            puts ">> tailscale up -ssh"
            pid = Process.spawn('tailscale up --ssh > /dev/null 2>&1 &')
            Process.detach(pid)
            puts "up 🎉"
            render json: { message: "up 🎉" }, status: :ok
        end
    end

    def check
        puts ">> tailscale check"
        unless File.exist?("#{Rails.root}/tmp/tailscale.txt")
            puts "tailscale.txt not found"
            render json: { message: "tailscale.txt not found" }, status: :ok
        else
            puts "tailscale.txt found"
            output = File.read("#{Rails.root}/tmp/tailscale.txt")
            render plain: output
        end
    end

    def down
        puts ">> tailscale down"
        pid = Process.spawn('tailscale down > /dev/null 2>&1 &')
        Process.detach(pid)
        puts "down 🎉"
        render json: { message: "down 🎉" }, status: :ok
    end

    def status
        puts ">> tailscale status"
        # tailscale statusを実行
        stdout, stderr, status = Open3.capture3('tailscale status')
        if status.success?
            puts "status 🎉 : #{ stdout.strip }" 
            render json: { message: "status🎉 : #{ stdout.strip }"  }, status: :ok
        else
            puts "❌ : #{ stderr.strip }"
            render json: { error: "❌ : #{ stderr.strip }" }, status: :internal_server_error
        end
    end
end
# ------------------------------------------------------------------------------
    # def up
    #     output = ""
    #     Open3.popen2e('tailscale up -ssh') do |stdin, stdout_and_stderr, wait_thr|
    #         Thread.new do
    #             stdout_and_stderr.each { |line| output += line }
    #         end
    #         render json: { message: output }, status: :accepted
    #     end
    # end
    # def up
    #     unless File.exist?('tmp/tailscale.txt')
    #         pid = Process.spawn("tailscale up -ssh > #{Rails.root}/tmp/tailscale.txt 2>&1 &")
    #         Process.detach(pid) # プロセスをデタッチしてバックグラウンドで実行
    #         sleep 3 # コマンドの出力を待つための小さな遅延
    #         output = File.read("#{Rails.root}/tmp/tailscale.txt")
    #         render plain: output
    #     else
    #         puts ">> tailscale up -ssh"
    #         pid = Process.spawn('tailscale up -ssh > /dev/null 2>&1 &')
    #         Process.detach(pid) # プロセスをデタッチしてバックグラウンドで実行
    #         puts "🎉"
    #         render json: { message: "🎉" }, status: :ok 
    #         # stdout, stderr, status, wait_thr = Open3.capture3('tailscale up -ssh')
    #         # if status.success?
    #         #     File.delete('tmp/tailscale.txt')
    #         #     puts "🎉 : #{ stdout.strip }" 
    #         #     render json: { message: "🎉 : #{ stdout.strip }" }, status: :ok
    #         # else
    #         #     puts "❌ : #{ stderr.strip }"
    #         #     render json: { error: "❌ : #{ stderr.strip }" }, status: :internal_server_error
    #         # end
    #     end
    # end

    # def down
    #     puts ">> tailscale down"
    #     pid = Process.spawn('tailscale down > /dev/null 2>&1 &')
    #     Process.detach(pid) # プロセスをデタッチしてバックグラウンドで実行
    #     puts "🎉"
    #     render json: { message: "🎉" }, status: :ok
    # end
    # def up
    #     output = `tailscale up -ssh 2>&1`
    #     render plain: output
    # end
    # def up
    #     system('tailscale up -ssh > tmp/tailscale.txt 2>&1 &')
    #     sleep 1 # コマンドの出力を待つための小さな遅延
    #     output = File.read('tmp/tailscale.txt')
    #     render plain: output
    # end
    # def up
    #     begin
    #         output = ""
    #         Timeout::timeout(3) do
    #             Open3.popen3('tailscale up -ssh') do |stdin, stdout, stderr, wait_thr|
    #                 stdout.each do |line|
    #                     output += line
    #                 end
    #                 status = wait_thr.value
    #                 if status.success?
    #                     render json: { message: output.strip }, status: :ok
    #                 else
    #                     render json: { error: stderr.read.strip }, status: :internal_server_error
    #                 end
    #             end
    #         end
    #     rescue Timeout::Error
    #         render json: { error: 'Command execution timed out' }, status: :request_timeout
    #     end
    # end
    # def up
    #     # tailscale up -ssh
    #     puts ">> tailscale up -ssh"
    #         stdout, stderr, status, wait_thr = Open3.capture3('tailscale up -ssh')
    #     # puts "stdout: #{ stdout }"
    #     # render json: { message: "🚀 : #{ stdout.strip }" }, status: :ok
    #     # if status.success?
    #     #     puts "🎉 : #{ stdout.strip }" 
    #     #     render json: { message: "🎉 : #{ stdout.strip }" }, status: :ok
    #     # else
    #     #     puts "❌ : #{ stderr.strip }"
    #         render json: { error: "❌ : #{ wait_thr.value }" }, status: :internal_server_error
    #     # end
    # end

    # def down
    #     puts ">> tailscale down"
    #     # tailscale down
    #     stdout, stderr, status = Open3.capture3('tailscale down')
    #     if status.success?
    #         puts "🎉 : #{ stdout.strip }" 
    #         render json: { message: "🎉 : #{ stdout.strip }"  }, status: :ok 
    #     else
    #         puts "❌ : #{ stderr.strip }"
    #         render json: { error: "❌ : #{ stderr.strip }" }, status: :internal_server_error
    #     end
    # end