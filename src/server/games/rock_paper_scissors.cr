require "../../common/game"

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
