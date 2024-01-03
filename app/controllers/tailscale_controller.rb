require 'open3'

class TailscaleController < ApplicationController
    def up
        stdout, stderr, status = Open3.capture3(
            'tailscaled --tun=userspace-networking --socks5-server=localhost:1055 --outbound-http-proxy-listen=localhost:1055 & \
            && sudo tailscale up'
            )
        if status.success?
            puts "🎉 tailscale up is successful : #{ stdout.strip }" 
            render json: { message: stdout.strip }, status: :ok
        else
            puts "❌ tailscale up is failed : #{ stderr.strip }"
            render json: { error: stderr.strip }, status: :internal_server_error
        end
    end
end