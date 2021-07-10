require "../../spec_helper"

extend FourInARow::Assertions

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
    assert_all(g, '.', except: [{0,0}])

    g.play!(p2.id, "c")
    assert_cell(g, '*', 0, 0)
    assert_cell(g, 'o', col: 2, row: 0)
    assert_all(g, '.', except: [{0,0}, {2,0}])
    
    g.play!(p1.id, "c")
    assert_cells(g, '*', [{0,0}, {2,1}])
    assert_cell(g, 'o', 2, 0)
    assert_all(g, '.', except: [{0,0}, {2,0}, {2,1}])

    g.play!(p2.id, "d")
    assert_cells(g, '*', [{0,0}, {2,1}])
    assert_cells(g, 'o', [{2, 0}, {3,0}])
  end

end

