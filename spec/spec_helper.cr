require "spec"
require "../src/server/multiplayer_server"
require "../src/server/games/*"

module FourInARow::Assertions
  BoardCoords = (0...FourInARow::Width).flat_map { |col|
    (0...FourInARow::Height).map { |row|
      {col, row}
    }
  }

  def assert_cell(game : FourInARow, value : Char, col : Int32, row : Int32)
    game.state_info
      .not_nil!
      .state
      .char_at((FourInARow::Width + 1) * (FourInARow::Height - row - 1) + col)
      .should eq value
  end

  def assert_cells(game : FourInARow, value : Char, coords : Array({Int32, Int32}))
    coords.each { |(col, row)|
      assert_cell(game, value, col, row)
    }
  end

  def assert_all(game : FourInARow, value : Char, *, except : Array({Int32, Int32}) = [] of {Int32, Int32})
    assert_cells(game, value, BoardCoords.reject { |c| except.includes?(c) })
  end
end
