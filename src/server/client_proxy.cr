require "../common/game"

# A thread-safe proxy for client operations
class ClientProxy
  getter ip : String
  getter username : String
  record Write, msg : Game::ServerEvent | Game::ServerInfo

  def initialize(@socket : TCPSocket, @username : String)
    @ip = @socket.remote_address.address

    @ch = Channel(Write).new # (128)
    spawn(name: player_id) {
      loop do
        case m = @ch.receive
        in Write
          @socket.puts(m.msg)
        end
      end
    }
  end

  def puts(msg)
    select
    when @ch.send Write.new(msg)
    when timeout(2.seconds)
      # TODO: report timeout
      ::puts "#{Fiber.current.name} Timed out"
      @socket.close
      @ch.close
    end
  end

  def gets
    @socket.gets || raise Exception.new("Received nil")
  end

  def player_id
    "#{@ip}:#{@username}"
  end
end