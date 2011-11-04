# this is a test program, tests out tabbed panes. type F1 to exit
#
require 'rbcurse'
require 'rbcurse/extras/newmessagebox'

def alertme mess, config={}

  _title = config[:title] || "Alert"
    tp = NewMessagebox.new config do
      title _title
      button_type :ok
      message mess
      #text mess
    end
    tp.run
end
def textdialog mess, config={}
  _title = config[:title] || "Alert"
    tp = NewMessagebox.new config do
      title _title
      button_type :ok
      text mess
    end
    tp.run

end
def newget_string string, config={}

end
include RubyCurses
class SetupMessagebox
  def run
    $config_hash ||= Variable.new Hash.new
    #configvar.update_command(){ |v| $config_hash[v.source()] = v.value }

    #tp = NewMessagebox.new :row => 3, :col => 7, :width => 60, :height => 20 , :color => :white, :bgcolor => :blue do
    tp = NewMessagebox.new :color => :white, :bgcolor => :blue do
      title "User Setup"
      button_type :ok_apply_cancel
        item Field.new nil, :row => 2, :col => 2, :text => "enter your name", :label => ' Name: '
        item Field.new nil, :row => 3, :col => 2, :text => "enter your email", :label => 'Email: '
        r = 4
        item Label.new nil, :text => "Text", :row => r+1, :col => 2, :attr => 'bold'
        item CheckBox.new nil, :row => r+2, :col => 2, :text => "Antialias text"
        item CheckBox.new nil, :row => r+3, :col => 2, :text => "Use bold fonts"
        item CheckBox.new nil, :row => r+4, :col => 2, :text => "Allow blinking text"
        item CheckBox.new nil, :row => r+5, :col => 2, :text => "Display ANSI Colors"
=begin
        item Label.new nil, :text => "Cursor", :row => 7, :col => 2, :attr => 'bold'
        $config_hash.set_value Variable.new, :cursor
        item RadioButton.new nil, :row => 8, :col => 2, :text => "Block", :value => "block", :variable => $config_hash[:cursor]
        item RadioButton.new nil, :row => 9, :col => 2, :text => "Blink", :value => "blink", :variable => $config_hash[:cursor]
        item RadioButton.new nil, :row => 10, :col => 2, :text => "Underline", :value => "underline", :variable => $config_hash[:cursor]
      end
      tab "&Term" do
        
        item Label.new nil, :text => "Arrow Key in Combos", :row => 2, :col => 2, :attr => 'bold'
        x = Variable.new
        $config_hash.set_value x, :term
        item RadioButton.new nil, :row => 3, :col => 2, :text => "ignore", :value => "ignore", :variable => $config_hash[:term]
        item RadioButton.new nil, :row => 4, :col => 2, :text => "popup", :value => "popup", :variable => $config_hash[:term]
        item RadioButton.new nil, :row => 5, :col => 2, :text => "next", :value => "next", :variable => $config_hash[:term]
        cb = ComboBox.new nil, :row => 7, :col => 2, :display_length => 15, 
          :list => %w[xterm xterm-color xterm-256color screen vt100 vt102],
          :label => "Declare terminal as: "
        #radio.update_command() {|rb| ENV['TERM']=rb.value }
        item cb
        x.update_command do |rb|
          cb.arrow_key_policy=rb.value.to_sym
        end
        
      end
      tab "Conta&iner" do
        item r
      end
      # tell tabbedpane what to do if a button is pressed (ok/apply/cancel)
=end
      command do |eve|
        case eve.event
        when 0,2                   # ok cancel
          alertme "user pressed button index:#{eve.event}, #{eve.action_command} "
          throw :close, eve.event
        when 1                     # apply
          textdialog "user pressed apply: #{eve.to_s.length} : #{eve} "
        end
      end
    end
    tp.run
  end

end
if $0 == __FILE__
  # Initialize curses
  begin
    # XXX update with new color and kb
    VER::start_ncurses  # this is initializing colors via ColorMap.setup
    $log = Logger.new((File.join(ENV["LOGDIR"] || "./" ,"rbc13.log")))
    $log.level = Logger::DEBUG
    tp = SetupMessagebox.new()
    buttonindex = tp.run
    $log.debug "XXX:  MESSAGEBOX retirned #{buttonindex} "
  rescue => ex
  ensure
    VER::stop_ncurses
    p ex if ex
    p(ex.backtrace.join("\n")) if ex
    $log.debug( ex) if ex
    $log.debug(ex.backtrace.join("\n")) if ex
  end
end