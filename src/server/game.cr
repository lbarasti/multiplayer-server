require "./games/*"

abstract class Game
  GAME_TYPE = {"RPS" => RockPaperScissors, "C4" => FourInARow}

  abstract def play(player_id : PlayerId, move : Game::Move)

  def play!(player_id, move)
    self.play player_id, self.parse_move?(move).not_nil!
  end
end
