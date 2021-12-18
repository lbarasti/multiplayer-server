require "../../common/game"
require "uuid"

abstract class FightObj; end
class FightPl < FightObj
  getter id : UUID
  getter health : Int32
  property x : Int32 = 0
  property y : Int32 = 0

  def initialize(@id : UUID)
    @health = 100
  end

  def damage(x : Int32)
    @health -= x
  end

  def alive?
    @health > 0
  end
end

class FightMine < FightObj
  getter id : UUID
  property x : Int32
  property y : Int32
  def initialize(@x, @y)
    @id = UUID.random
  end
end

class Fight < Game
  getter min_players : Int32 = 1

  enum Moves
    Left; Right; Up; Down; Drop
  end

  @state = {} of UUID => FightObj
  @player_to_uuid = {} of PlayerId => UUID

  class Move
    include Game::Move
    getter move
    def initialize(@move : Moves)
    end
  end

  def play(player_id : PlayerId, move : Game::Move)
    move = move.as(Move)
    
    p_id = @player_to_uuid[player_id]? || (@player_to_uuid[player_id] = UUID.random)

    if pl = @state[p_id]?
      case move.move
      when Moves::Left
        pl.x -= 1
      when Moves::Right
        pl.x += 1
      when Moves::Up
        pl.y -= 1
      when Moves::Down
        pl.y +=1
      when Moves::Drop
        new_mine = FightMine.new(pl.x, pl.y)
        @state[new_mine.id] = new_mine
      end
    else
      # create player
      @state[p_id] = FightPl.new(p_id)
    end
  end

  def parse_move?(move) : Move?
    {
      "A" => Moves::Left, "S" => Moves::Down,
      "D" => Moves::Right, "W" => Moves::Up, " " => Moves::Drop
    }[move.upcase]?.try { |m| Move.new(m) }
  end

  def state_info
    GameStateInfo.new(@state.inspect)
  end

  def winner? : PlayerId?
    nil # game never ends
  end
end