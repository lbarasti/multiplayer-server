require "random"

alias PlayerId = String
alias GameId = String

record Player, id : PlayerId

abstract class Game
  abstract struct ServerEvent; end

  abstract struct ServerInfo; end

  module Events
    record GameCreated < ServerEvent, id : GameId
    record PlayerJoinedServer < ServerEvent, name : String
    record PlayerJoined < ServerEvent, game_id : GameId
    record PlayerLeft < ServerEvent, player_id : PlayerId, game_id : GameId
    record PlayerWon < ServerEvent, player_id : PlayerId?
    record PlayerMoved < ServerEvent, player_id : PlayerId
    record JoinFailed < ServerEvent, game_id : GameId
    record InvalidCommandEntered < ServerEvent, cmd : String?
  end

  module Info
    record GameList < ServerInfo, msg : String
    record GameStateInfo < ServerInfo, state : String
  end

  getter id : GameId = Random::Secure.hex(1)
  property players : Array(Player) = [] of Player
  getter status : GameStatus = GameStatus::AwaitingPlayers
  getter turn : PlayerId?

  enum GameStatus
    AwaitingPlayers
    Ready
    Playing
    Over
  end

  module Move; end

  # TODO: Return T < Error when #play does not apply the given move
  # module Error
  # def try(&block)
  #   self
  # end
  # end

  def add_player(player : Player)
    return if @status == GameStatus::Over
    @players << player
    if @players.size >= min_players
      @status = GameStatus::Playing
      @turn = @players.first.id
    end
    @players
  end

  def remove_player(player_id)
    @players.reject! { |player| player.id == player_id }
  end

  def broadcast(msg, player2socket)
    # puts has a 2 seconds timeout, so a slow client could slow comms down
    @players.each { |pl|
      player2socket[pl.id]?.try(&.puts msg)
    }
  end

  abstract def parse_move?(move) : Game::Move?
  abstract def play(player_id : PlayerId, move : Move)
  abstract def min_players : Int32
end
