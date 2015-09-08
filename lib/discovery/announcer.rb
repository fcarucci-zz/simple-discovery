require 'discovery'

require "socket"
require "timeout"

require "awesome_print"

module Discovery
  class Announcer
    def add_service(name:, description: "", address:, port: )
      @services[name] = { description: "", address: address, port: port}
    end

    def remove_service(name:)
      @services.delete name

    end

    def reply(ip, port, response)
      s = UDPSocket.new
      s.send(Marshal.dump(response), 0, ip, port)
      s.close
    end

    def initialize
      @services = {}
      @thread = Thread.fork do
        begin
          s = UDPSocket.new
          s.bind('0.0.0.0', PORT)

          loop do
            body, sender = s.recvfrom(1024)
            data = Marshal.load(body)
            client_ip = sender[3]

            services = @services.map { |name, service| service[:name] = name; service }

            yield(client_ip, data)

            response = { msg: "Discovery/Announcer", host: Socket.gethostname, services: services }
            reply(client_ip, data[:port], response) unless data[:port].nil?
          end
        rescue Interrupt
        ensure
          s.close
        end
      end
    end

    def join
      @thread.join
    end
  end
end
