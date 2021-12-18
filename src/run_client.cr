require "socket"
require "crysterm"
require "uuid"

socket = TCPSocket.new("localhost", 1234)

record Mine, x : Int32, y : Int32, id : UUID = UUID.random

class MyProg
  include Crysterm

  d = Display.global
  s = Screen.global

  b = Widget::Box.new top: 0, left: 0, width: "100%", height: "100%", border: true

  # box = Widget::Box.new(
  #   parent: b,
  #   width: 3,
  #   height: 2,
  #   border: BorderType::Line,
  # )
  # enemy = Widget::Box.new(
  #   parent: b,
  #   width: 3,
  #   height: 2,
  #   border: BorderType::Line,
  #   left: 20,
  #   top: 12
  # )

  s.append b
  ui_objects = {} of UUID => Widget::Box

  mode = :cmd
  buffer = ""
  x, y = 0, 0
  objects = [] of Mine
  updates = Channel(String).new(10)

  spawn do
    while rec = socket.gets
      updates.send(rec)
    end
  end

  spawn do
    while msg = updates.receive?
      b.set_content(msg)
      s.render
    end
  end

  d.on(Event::KeyPress) do |e|
    exit if e.key == Tput::Key::CtrlQ
    
    if e.key == Tput::Key::Escape
      # change mode
      mode = (mode == :cmd) ? :game : :cmd
    else
      if mode == :cmd
        if e.key == Tput::Key::Enter
          updates.send("sending #{buffer}")
          socket.puts(buffer)
          buffer = ""
        else
          buffer += e.char
          updates.send buffer
        end
      else
        updates.send("sending #{e.char}")
        socket.puts(e.char)
      end
    end

    # update UI
    # box.rtop = y
    # box.rleft = x
    # objects.each { |m|
    #   m_x, m_y, id = m.x, m.y, m.id
    #   unless ui_objects[id]?
    #     ui_objects[id] = Widget::Box.new(
    #       parent: b,
    #       width: 2,
    #       height: 2,
    #       border: BorderType::Line,
    #       left: m_x,
    #       top: m_y
    #     )
    #   end 
    # }

    # s.render
  end

  d.exec
end