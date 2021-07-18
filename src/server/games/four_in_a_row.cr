require "../../common/game"

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
    if player_id == @turn && @status != GameStatus::Over
      move = move.as(Move)
      p1, p2 = @players.map(&.id)
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
    return nil if @players.size < 2
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

  private def full?
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