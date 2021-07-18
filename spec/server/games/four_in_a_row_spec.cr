require "../../spec_helper"

extend FourInARow::Assertions

def play_sequence(game, p1, p2, string)
  string.split(//)
    .zip([p1, p2].cycle)
    .each { |(mv, pl)|
      game.play!(pl.id, mv)
    }
end

describe FourInARow do
  p1 = Player.new("abc")
  p2 = Player.new("def")

  it "defines width and height constants" do
    FourInARow::Width.should eq 7
    FourInARow::Height.should eq 6
  end

  it "sets up an empty board once 2 players join" do
    g = FourInARow.new
    g.state_info.should eq nil
    g.add_player(p1)
    g.state_info.should eq nil
    g.add_player(p2)

    assert_all(g, '.')
  end

  it "lets players play moves" do
    g = FourInARow.new
    g.state_info.should eq nil
    g.add_player(p1)
    g.state_info.should eq nil
    g.add_player(p2)

    g.play!(p1.id, "a")
    assert_cell(g, '*', 0, 0)
    assert_all(g, '.', except: [{0, 0}])

    g.play!(p2.id, "c")
    assert_cell(g, '*', 0, 0)
    assert_cell(g, 'o', col: 2, row: 0)
    assert_all(g, '.', except: [{0, 0}, {2, 0}])

    g.play!(p1.id, "c")
    assert_cells(g, '*', [{0, 0}, {2, 1}])
    assert_cell(g, 'o', 2, 0)
    assert_all(g, '.', except: [{0, 0}, {2, 0}, {2, 1}])

    g.play!(p2.id, "d")
    assert_cells(g, '*', [{0, 0}, {2, 1}])
    assert_cells(g, 'o', [{2, 0}, {3, 0}])
  end

  it "lets players win when they connect 4 vertically" do
    g = FourInARow.new
    g.add_player(p1)
    g.add_player(p2)

    play_sequence(g, p1, p2, "acadaea")

    g.state_info.try(&.state).should eq(
      ".......\n" \
      ".......\n" \
      "*......\n" \
      "*......\n" \
      "*......\n" \
      "*.ooo..")

    g.winner?.should eq p1.id
  end

  it "lets players win when they connect 4 horizontally" do
    g = FourInARow.new
    g.add_player(p1)
    g.add_player(p2)

    play_sequence(g, p1, p2, "acadaecf")

    g.state_info.try(&.state).should eq(
      ".......\n" \
      ".......\n" \
      ".......\n" \
      "*......\n" \
      "*.*....\n" \
      "*.oooo.")

    g.winner?.should eq p2.id
  end

  it "lets players win when they connect 4 diagonally" do
    g = FourInARow.new
    g.add_player(p1)
    g.add_player(p2)

    play_sequence(g, p1, p2, "bccddedefee")

    g.state_info.try(&.state).should eq(
      ".......\n" \
      ".......\n" \
      "....*..\n" \
      "...*o..\n" \
      "..**o..\n" \
      ".*ooo*.")

    g.winner?.should eq p1.id
  end

  it "lets players fill the board" do
    g = FourInARow.new
    g.add_player(p1)
    g.add_player(p2)

    play_sequence(g, p1, p2, "eccddbdefeddfedccccb")

    g.state_info.try(&.state).should eq(
      "..**...\n" \
      "..oo...\n" \
      "..**o..\n" \
      "..o*o..\n" \
      ".o**o*.\n" \
      ".ooo**.")

    g.winner?.should eq nil

    play_sequence(g, p1, p2, "aaaaaabbbbeeffffgggggg")

    g.state_info.try(&.state).should eq(
      "oo**ooo\n" \
      "**oo***\n" \
      "oo**ooo\n" \
      "**o*o**\n" \
      "oo**o*o\n" \
      "*ooo***")
    
    g.status.should eq Game::GameStatus::Over
    g.winner?.should eq nil
  end
end
