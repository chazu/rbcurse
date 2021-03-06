#$LOAD_PATH << "/Users/rahul/work/projects/rbcurse/"
require 'logger'
#require 'lib/rbcurse/mapper'
#require 'lib/rbcurse/core/widgets/keylabelprinter'
#require 'lib/rbcurse/commonio'
#require 'lib/rbcurse/core/widgets/rwidget'
#require 'lib/rbcurse/rform'
require 'rbcurse/extras/widgets/rcomboedit'
if $0 == __FILE__
  include RubyCurses

  begin
  # Initialize curses
    VER::start_ncurses  # this is initializing colors via ColorMap.setup
    $log = Logger.new((File.join(ENV["LOGDIR"] || "./" ,"rbc13.log")))
    $log.level = Logger::DEBUG

    @window = VER::Window.root_window
    # Initialize few color pairs 
    # Create the window to be associated with the form 
    # Un post form and free the memory

    catch(:close) do
      @form = Form.new @window
      r = 1; c = 30;
      mylist = []
      0.upto(100) { |i| mylist << i.to_s }
      combo = ComboBoxEdit.new @form do
        name "combo"
        row r
        col c
        bgcolor :magenta
        display_length 10
        editable false
        list mylist
        set_label Label.new @form, {'text' => "Non-edit Combo"}
        list_config 'color' => 'black', 'bgcolor'=>'magenta', 'max_visible_items' => 6
      end
      r+=1
      $results = Variable.new
      $results.value = "Event:"
      status = RubyCurses::Label.new @form, {'text_variable' => $results, "row" => 22, "col" => 2}
      # since updated from another window, so explicit repaint required
      $results.update_command { status.repaint }

      v_positions = [:BELOW, :SAME, :CENTER, :CENTER, :ABOVE, :ABOVE]
      #h_positions = [:SAME, :LEFT, :RIGHT, :SAME, :SAME, :ABOVE]
      policies = [:NO_INSERT, :INSERT_AT_TOP, :INSERT_AT_BOTTOM, 
        :INSERT_AT_CURRENT, :INSERT_BEFORE_CURRENT, :INSERT_AFTER_CURRENT]
      policies.each_with_index do |policy, ix|
          name="combo#{r}"
          list = ListDataModel.new( %w[spotty tiger secret pass torvalds qwerty quail toiletry])
          list.bind(:LIST_DATA_EVENT, name) { |lde,n| $results.value = lde.to_s[0,70]; $log.debug " STA: #{$results} #{lde}"  }
          list.bind(:ENTER_ROW, name) { |obj,n| $results.value = "ENTER_ROW :#{obj.current_index} : #{obj.selected_item}    "; $log.debug " ENTER_ROW: #{$results.value} , #{obj}"  }
        ComboBoxEdit.new @form do
          name name
          row r
          col 30
          display_length 10
          bgcolor 'cyan'
          editable true
          #list %w[spotty tiger secret pass torvalds qwerty quail toiletry]
          list_data_model list
          insert_policy policy
          set_label Label.new @form, {'text' => "Combo: "+policy.to_s}
          list_config 'color' => 'white', 'bgcolor'=>'blue', 'valign' => v_positions[ix]
        end
        r+=2
      end

      @help = "Use UP and DOWN to navigate values, alt-DOWN for popup, TAB / BACKTAB between fields. F10-quit"
      RubyCurses::Label.new @form, {'text' => @help, "row" => 21, "col" => 2, "color" => "yellow"}

      @form.repaint
      @window.wrefresh
      Ncurses::Panel.update_panels
      while((ch = @window.getchar()) != KEY_F10 )
        @form.handle_key(ch)
        @window.wrefresh
      end
    end
  rescue => ex
  ensure
    @window.destroy if !@window.nil?
    VER::stop_ncurses
    p ex if ex
    p(ex.backtrace.join("\n")) if ex
    $log.debug( ex) if ex
    $log.debug(ex.backtrace.join("\n")) if ex
  end
end
