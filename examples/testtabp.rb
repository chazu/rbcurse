require 'logger'
require 'rbcurse'
#require 'rbcurse/rtabbedpane'
require 'rbcurse/rtabbedwindow'

class TestTabbedPane
  def initialize
    acolor = $reversecolor
    #$config_hash ||= {}
  end
  def run
    $config_hash ||= Variable.new Hash.new
    #configvar.update_command(){ |v| $config_hash[v.source()] = v.value }
      @tw = RubyCurses::TabbedWindow.new nil  do
        height 18
        width  60
        row 5
        col 20
        button_type :ok
      end
      @tp = @tw.tabbed_pane
      @tab1 = @tw.add_tab "&Language" 
      f1 = @tp.form @tab1
      #$radio = Variable.new
      radio1 = RadioButton.new f1 do
        #variable $radio
        variable $config_hash
        name "radio1"
        text "ruby"
        value "ruby"
        color "red"
        row 4
        col 2
      end
      radio2 = RadioButton.new f1 do
        #variable $radio
        variable $config_hash
        name "radio1"
        text  "jruby"
        value  "jruby"
        color "green"
        row 5
        col 2
      end
      radio3 = RadioButton.new f1 do
        #variable $radio
        variable $config_hash
        name "radio1"
        text  "macruby"
        value  "macruby"
        color "cyan"
        row 6
        col 2
      end
      @tab2 = @tw.add_tab "&Settings"
      #f2 = @tab2.form
      f2 = @tp.form @tab2
      r = 2
      butts = [ "Use &HTTP/1.0", "Use &frames", "&Use SSL" ]
      bcodes = %w[ HTTP, FRAMES, SSL ]
      butts.each_with_index do |t, i|
        RubyCurses::CheckBox.new f2 do
          text butts[i]
          variable $config_hash
          name bcodes[i]
          row r+i
          col 4
        end
      end
      @tab3 = @tw.add_tab "&Editors"
      #f3 = @tab3.form
      f3 = @tp.form @tab3
      butts = %w[ &Vim E&macs &Jed &Other ]
      bcodes = %w[ VIM EMACS JED OTHER]
      row = 3
      butts.each_with_index do |name, i|
        RubyCurses::CheckBox.new f3 do
          text name
          variable $config_hash
          name bcodes[i]
          row row
          col 4
        end
        row +=1
      end
      @tw.show
      @tw.handle_keys
  end
end
if $0 == __FILE__
  # Initialize curses
  begin
    # XXX update with new color and kb
    VER::start_ncurses  # this is initializing colors via ColorMap.setup
    $log = Logger.new((File.join(ENV["LOGDIR"] || "./" ,"rbc13.log")))
    $log.level = Logger::DEBUG
    n = TestTabbedPane.new
    n.run
  rescue => ex
  ensure
    VER::stop_ncurses
    p ex if ex
    p(ex.backtrace.join("\n")) if ex
    $log.debug( ex) if ex
    $log.debug(ex.backtrace.join("\n")) if ex
  end
end
