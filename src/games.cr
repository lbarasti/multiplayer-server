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
  # module Error; end # TODO: Return T < Error when #play does not apply the given move

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

  GAME_TYPE = {"RPS" => RockPaperScissors, "C4" => FourInARow}
end

class RockPaperScissors < Game
  getter min_players : Int32 = 2
  @winner : PlayerId? = nil

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

  def state_info
    nil
  end

  def play(player_id : PlayerId, move : Game::Move)
    move = move.as(Move)
    if @status == GameStatus::Playing
      @state[player_id] = move
      if @state.size == 2
        @status = GameStatus::Over
        p1, p2 = @players.map { |pl| {pl.id, @state[pl.id].move} }
        res = (p1.last.value - p2.last.value) % 3
        @winner = case res
        when 1; p1.first
        when 2; p2.first
        end
      end
    end
  end

  def winner? : PlayerId?
    @winner
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

class FourInARow < Game
  Width = 7
  Height = 6
  getter min_players : Int32 = 2
  getter turn : PlayerId?

  enum Moves
    A; B; C; D; E; F; G
  end

  @state : Hash(Int32, Array(PlayerId)) =
    Hash(Int32, Array(PlayerId)).new { |h, k| h[k] = [] of PlayerId }

  class Move
    include Game::Move
    getter move
    def initialize(@move : Moves)
    end
  end

  def play(player_id : PlayerId, move : Game::Move)
    move = move.as(Move)
    p1, p2 = @players.map(&.id)
    if player_id == @turn
      if @state[move.move.value].size < Height
        @state[move.move.value] << player_id
        @turn = player_id == p1 ? p2 : p1
        if winner? || full?
          @status = GameStatus::Over
        end
        @status
      else
        nil # ColumnFull.new(col)
      end
    else
      nil # NotYourTurn.new(@turn, player)
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

  def state_info
    p1, p2 = @players.map(&.id)
    st = (0...Height).map { |r_idx|
      (0...Width).map { |c_idx|
        case @state[c_idx][r_idx]?
        when p1
          "*"
        when p2
          "o"
        else
          "."
        end
      }.join
    }.reverse.join("\n")
    GameStateInfo.new(st)
  end

  def full?
    @state.values.reduce(0) { |acc, col| acc += col.size } >= Width * Height
  end

  def winner? : PlayerId?
    @state.each { |c_idx, col|
      col.each_with_index { |pl, r_idx|
        return pl if [{0, 1}, {1, 0}, {1, 1}, {-1, 1}].any? { |(c_incr, r_incr)| has_4_in_direction?(pl, c_idx, r_idx, c_incr, r_incr) }
      }
    }
  end

  private def has_4_in_direction?(player, col_idx, row_idx, col_factor, row_factor)
    (1..3).all? { |t|
      (0 <= col_idx + col_factor * t < Width) ?
        @state[col_idx + col_factor * t][row_idx + row_factor * t]? == player : false}
  end
end