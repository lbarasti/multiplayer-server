require "socket"
require "./client_proxy"
require "./game"
include Game::Events
include Game::Info

class MultiplayerServer
  @player2socket : Hash(PlayerId, ClientProxy) = Hash(PlayerId, ClientProxy).new
  @games : Hash(GameId, Game) = Hash(GameId, Game).new

  def initialize(address, port)
    @server = TCPServer.new(address, port)
  end

  def _connected(_socket)
    case cmd = _socket.gets
    when /\\u /
      _, name = cmd.not_nil!.split(" ")
      client = ClientProxy.new(_socket, name)
      player_id = client.player_id
      @player2socket[player_id] = client
      client.puts PlayerJoinedServer.new(name)
      _lobby(player_id, client)
    else
      _socket.puts InvalidCommandEntered.new(cmd)
      _connected(_socket)
    end
  end

  def _lobby(player_id, client)
    case cmd = client.gets
    when /new /
      _, game_type = cmd.not_nil!.split(" ")
      if game = Game::GAME_TYPE[game_type]?.try(&.new)
        @games[game.id] = game
        game.add_player Player.new(player_id)
        client.puts GameCreated.new(game.id)
        _playing(player_id, client, game)
      else
        client.puts InvalidCommandEntered.new("Unknown game")
      end
    when /join /
      _, game_id = cmd.not_nil!.split(" ")
      if game = @games[game_id]?
        if game.add_player Player.new(player_id)
          client.puts PlayerJoined.new(game_id: game_id)
          _playing(player_id, client, game)
        else
          client.puts JoinFailed.new(game_id)
          _lobby(player_id, client)
        end
      else
        client.puts JoinFailed.new(game_id)
        _lobby(player_id, client)
      end
    when /^ls$/
      games_with_status = @games.map { |id, g| {id, g.class, g.status} }.join("\n")
      client.puts GameList.new(games_with_status)
      _lobby(player_id, client)
    else
      client.puts InvalidCommandEntered.new(cmd)
      _lobby(player_id, client)
    end
  end

  def _playing(player_id, client, game)
    cmd = client.gets
    return _playing(player_id, client, game) unless cmd
    case move = game.parse_move?(cmd)
    when Game::Move
      game.play(player_id, move).try {
        game.broadcast(PlayerMoved.new(player_id), @player2socket)
        if st_info = game.state_info
          game.broadcast(st_info, @player2socket)
        end
      }
      if game.status == Game::GameStatus::Over
        game.broadcast(PlayerWon.new(game.winner?), @player2socket)
      end
      _playing(player_id, client, game)
    else
      if cmd == "quit"
        game.remove_player(player_id)
        game.broadcast(PlayerLeft.new(player_id, game.id), @player2socket)
        _lobby(player_id, client)
      else
        client.puts InvalidCommandEntered.new(cmd)
        _playing(player_id, client, game)
      end
    end
  end

  def handle_client(_socket)
    _connected(_socket)
  end

  def listen
    while client = @server.accept?
      spawn handle_client(client)
    end
  end
end
