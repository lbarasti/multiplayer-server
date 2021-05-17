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
    record PlayerWon < ServerEvent, player : Player?
    record JoinFailed < ServerEvent, game_id : GameId
    record InvalidCommandEntered < ServerEvent, cmd : String?
  end
  module Info
    record GameList < ServerInfo, msg : String
  end

  getter id : GameId = Random::Secure.hex(1)
  property players : Array(Player) = [] of Player
  getter status : GameStatus = GameStatus::AwaitingPlayers

  enum GameStatus
    AwaitingPlayers
    Ready
    Playing
    Over
  end

  module Move; end

  def add_player(player : Player)
    return if @status == GameStatus::Over
    @players << player
    if @players.size >= min_players
      @status = GameStatus::Playing
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
  abstract def play(player_id : PlayerId, move : Move) : Player?
  abstract def min_players : Int32

  GAME_TYPE = {"RPS" => RockPaperScissors}
end

class RockPaperScissors < Game
  getter min_players : Int32 = 2

  enum Moves
    Rock
    Paper
    Scissors
  end

  class Move
    include Game::Move
    getter move
    def initialize(@move : Moves)
    end
  end

  def initialize
    @state = Hash(PlayerId, Move).new
    super
  end

  def play(player_id : PlayerId, move : Move) : Player?
    if @status == GameStatus::Playing
      @state[player_id] = move
      if @state.size == 2
        @status = GameStatus::Over
        p1, p2 = @players.map { |pl| {pl, @state[pl.id].move} }
        case p1.last
        in Moves::Rock
          p2.last == Moves::Scissors ? p1 : p2.last == Moves::Paper ? p2 : nil
        in Moves::Paper
          p2.last == Moves::Scissors ? p2 : p2.last == Moves::Paper ? nil : p1
        in Moves::Scissors
          p2.last == Moves::Scissors ? nil : p2.last == Moves::Paper ? p1 : p2
        end.try(&.first)
      end
    end
  end

  def parse_move?(move) : Move?
    case mv = Moves.parse?(move)
    when Moves
      Move.new(mv)
    else
      nil
    end
  end
end