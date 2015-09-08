require 'simple_discovery'

require "socket"
require "timeout"

module Discovery

  class Browser
    attr_reader :services
    attr_reader :response

    def initialize
      @services = []
      listen
    end

    private

    def broadcast(target = '<broadcast>')
      body = {:port => PORT + 1, :content => nil}

      s = UDPSocket.new
      s.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true)
      s.send(Marshal.dump(body), 0, target, PORT)
      s.close
    end

    def listen(time_out = 3)
      s = UDPSocket.new
      s.bind('0.0.0.0', PORT + 1)

      begin
        broadcast
        body, sender = timeout(time_out) { s.recvfrom(1024) }
        server_ip = sender[3]
        data = Marshal.load(body)

        @response = data
        @services = data[:services]
      rescue Timeout::Error
        retry
      end
      s.close
    end
  end

end
