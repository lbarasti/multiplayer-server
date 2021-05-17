require "./games/*"

abstract class Game
  GAME_TYPE = {"RPS" => RockPaperScissors, "C4" => FourInARow}
end
