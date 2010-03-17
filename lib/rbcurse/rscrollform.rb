=begin
  * Name: ScrollForm - a form that can take more than the screen and focus only on what's visible
  *  This class originated in TabbedPane for the top button form which only scrolls
  *  horizontally and uses objects that have a ht of 1. Here we have to deal with
  * large objects and vertical scrolling.
  * Description: 
  * Author: rkumar
  
  --------
  * Date: 2010-03-16 11:32 
  * License:
    Same as Ruby's License (http://www.ruby-lang.org/LICENSE.txt)


NOTE: 
    There are going to be tricky cases we have to deal with such as objects that start in the viewable
area but finish outside, or vice versa.

    What if we wish some static text to be displayed at top or bottom of ScrollForm
=end
require 'rubygems'
require 'ncurses'
require 'logger'
require 'rbcurse'

include Ncurses
include RubyCurses
module RubyCurses
  extend self
  class ScrollForm < RubyCurses::Form
    # the pad prints from this col to window
    attr_accessor :pmincol # advance / scroll columns
    # the pad prints from this row to window, usually 0
    attr_accessor :pminrow # advance / scroll rows (vertically)
    attr_accessor :display_w # width of screen display
    attr_accessor :display_h # ht of screen display
    attr_accessor :row_offset, :col_offset
    attr_accessor :scroll_unit # by how much should be scroll
    attr_reader :orig_top, :orig_left
    attr_reader :window
    attr_accessor :name
    attr_reader :cols_panned, :rows_panned
    def initialize win, &block
      @target_window = win
      super
      @pminrow = @pmincol = 0
      @row_offset = @col_offset = 0
      @scroll_unit = 3
      @cols_panned = @rows_panned = 0
      @repaint_all = true

      # take display dimensions from window. It is safe to override immediately after form creation
      @display_h = win.height
      @display_w = win.width
      @display_h = (Ncurses.LINES - win.top - 2) if @display_h == 0
      @display_w = (Ncurses.COLS - win.left - 2) if @display_w == 0
      
      init_vars
    end
    def init_vars
      bind_key(?\M-h, :scroll_left)
      bind_key(?\M-l, :scroll_right)
      bind_key(?\M-n, :scroll_down)
      bind_key(?\M-p, :scroll_up)
    end
    def should_print_border flag=true
      @print_border_flag = flag
      @row_offset = @col_offset = 1
    end
    # This is how we set size of pad and where it prints on screen
    # This is all that's needed after constructor.
    # @param [Fixnum] t top (row on screen to print pad on)
    # @param [Fixnum] l left (col on screen to print)
    # @param [Fixnum] h height (how many lines in Pad, usually more that screens actual height)
    # @param [Fixnum] w width (how many cols in Pad, often more than screens width)
    #
    def set_pad_dimensions(t, l, h, w )
      @pad_h = h
      @pad_w = w
      @top = @orig_top = t
      @left = @orig_left = l
      create_pad
    end
    ## 
    # create a pad to work on. 
    # XXX We reuse window, which is already the main window
    # So if we try creating pad later, then old external window is used.
    # However, many methods in superclass operate on window so we needed to overwrite. What do i do ?
    private
    def create_pad
      raise "Pad already created" if @pad
      r = @top
      c = @left
      layout = { :height => @pad_h, :width => @pad_w, :top => r, :left => c } 
      @window = VER::Pad.create_with_layout(layout)
  
      @window.name = "Pad::ScrollPad" # 2010-02-02 20:01 
      @name = "Form::ScrollForm"
      @pad = @window
      return @window
    end
    public
    def scroll_right
      s = @scroll_unit + $multiplier; $multiplier = 0
      return false if !validate_scroll_col(@pmincol + s)
      @pmincol += @scroll_unit # some check is required or we'll crash
      @cols_panned -= s
      $log.debug " handled ch M-l in ScrollForm"
      @window.modified = true
      return 0
    end
    def scroll_left
      s = @scroll_unit + $multiplier; $multiplier = 0
      return false if !validate_scroll_col(@pmincol - s)
      @pmincol -= @scroll_unit # some check is required or we'll crash
      @cols_panned += s
      @window.modified = true
      return 0
    end
    def scroll_down
      s = @scroll_unit + $multiplier; $multiplier = 0
      return false if !validate_scroll_row(@pminrow + s)
      @pminrow += @scroll_unit # some check is required or we'll crash
      @rows_panned -= s
      @window.modified = true
      #@repaint_all = true
      return 0
    end
    def scroll_up
      s = @scroll_unit + $multiplier; $multiplier = 0
      return false if !validate_scroll_row(@pminrow - s)
      @pminrow -= @scroll_unit # some check is required or we'll crash
      @rows_panned += s
      @window.modified = true
      #@repaint_all = true
      return 0
    end
    ## ScrollForm handle key, scrolling
    def handle_key ch
      $log.debug " inside ScrollForm handle_key #{ch} "
      ret = process_key ch, self # field
      # some methods return 0 or false.
      return ret unless ret == :UNHANDLED

      super
    end
    # print a border on the main window, just for kicks
    def print_border
      $log.debug " SCROLL print_border ..."
      #@window.print_border_only(@top-@rows_panned, @left+@cols_panned, @display_h, @display_w, $datacolor)
      @target_window.print_border_only(@top, @left, @display_h, @display_w+1, $datacolor)
    end
    # XXX what if we want a static area at bottom ?
    # maybe we should rename targetwindow to window
    #  and window to pad
    #  super may need target window
    def repaint
      #unless @pad
        #create_pad
      #end
      print_border if @repaint_all and @print_border_flag
      $log.debug " scrollForm repaint calling parent #{@row} #{@col}+ #{@cols_panned} #{@col_offset} "
      _col = @orig_left
      super
      prefresh
      $log.debug " @target_window.wmove #{@row+@rows_panned+@row_offset}, #{@col+@cols_panned+@col_offset}  "
      @target_window.wmove @row+@rows_panned+@row_offset, @col+@cols_panned+@col_offset
      @window.modified = false
      @repaint_all = false
    end
    ## refresh pad onto window
    # I am now copying onto main window, else prefresh has funny effects
    def prefresh
      ## reduce so we don't go off in top+h and top+w
      $log.debug "  start ret = @buttonpad.prefresh( #{@pminrow} , #{@pmincol} , #{@top} , #{@left} , top + #{@display_h} left + #{@display_w} ) "
      if @pminrow + @display_h > @orig_top + @pad_h
        $log.debug " if #{@pminrow} + #{@display_h} > #{@orig_top} +#{@pad_h} "
        $log.debug " ERROR 1 "
        #return -1
      end
      if @pmincol + @display_w > @orig_left + @pad_w
      $log.debug " if #{@pmincol} + #{@display_w} > #{@orig_left} +#{@pad_w} "
        $log.debug " ERROR 2 "
        return -1
      end
      # actually if there is a change in the screen, we may still need to allow update
      # but ensure that size does not exceed
      if @top + @display_h > @orig_top + @pad_h
      $log.debug " if #{@top} + #{@display_h} > #{@orig_top} +#{@pad_h} "
        $log.debug " ERROR 3 "
        return -1
      end
      if @left + @display_w > @orig_left + @pad_w
      $log.debug " if #{@left} + #{@display_w} > #{@orig_left} +#{@pad_w} "
        $log.debug " ERROR 4 "
        return -1
      end
      # maybe we should use copywin to copy onto @target_window
      $log.debug "   ret = @window.prefresh( #{@pminrow} , #{@pmincol} , #{@top} , #{@left} , #{@top} + #{@display_h}, #{@left} + #{@display_w} ) "
      omit = 0
      # this works but if want to avoid copying border
      #ret = @window.prefresh(@pminrow, @pmincol, @top+@row_offset, @left+@col_offset, @top + @display_h - @row_offset , @left + @display_w - @col_offset)
      #
      ## Haha , we are back to the old notorious copywin which has given mankind
      # so much grief that it should be removed in the next round of creation.
      ret = @window.copywin(@target_window.get_window, @pminrow, @pmincol, @top+@row_offset, @left+@col_offset, 
            @top + @display_h - @row_offset , @left + @display_w - @col_offset,  0)

      $log.debug " copywin ret = #{ret} "
    end
    private
    def validate_scroll_row minrow
       return false if minrow < 0
      if minrow + @display_h > @orig_top + @pad_h
        $log.debug " if #{minrow} + #{@display_h} > #{@orig_top} +#{@pad_h} "
        $log.debug " ERROR 1 "
        return false
      end
      return true
    end
    def validate_scroll_col mincol
      return false if mincol < 0
      if mincol + @display_w > @orig_left + @pad_w
      $log.debug " if #{mincol} + #{@display_w} > #{@orig_left} +#{@pad_w} "
        $log.debug " ERROR 2 "
        return false
      end
      return true
    end
    # when tabbing through buttons, we need to account for all that panning/scrolling goin' on
    # this is typically called by putchar or putc in editable components like field.
    def setrowcol r, c
      $log.debug " SCROLL setrowcol #{r},  #{c} + #{@cols_panned}"
      # aha ! here's where i can check whether the cursor is falling off the viewable area
      cc = nil
      rr = nil
      if c
        cc = c #+ @cols_panned
        if c+@cols_panned < @orig_left
          # this essentially means this widget (button) is not in view, its off to the left
          $log.debug " setrowcol OVERRIDE #{c} #{@cols_panned} < #{@orig_left} "
          $log.debug " aborting settrow col for now"
          return
        end
        if c+@cols_panned > @orig_left + @display_w
          # this essentially means this button is not in view, its off to the right
          $log.debug " setrowcol OVERRIDE #{c} #{@cols_panned} > #{@orig_left} + #{@display_w} "
          $log.debug " aborting settrow col for now"
          return
        end
      end
      if r
        rr = r+@rows_panned
      end
      super rr, cc
    end
    public
    def add_widget w
      super
      $log.debug " inside add_widget #{w.name}  pad w #{@pad_w} #{w.col}, #{@pad_h}  "
      if w.col >= @pad_w
        @pad_w += 10 # XXX currently just a guess value, we need length and maybe some extra
        @window.wresize(@pad_h, @pad_w) if @pad
      end
      if w.row >= @pad_h
        @pad_h += 10 # XXX currently just a guess value, we need length and maybe some extra
        $log.debug " SCROLL add_widget ..."
        @window.wresize(@pad_h, @pad_w) if @pad
      end
    end
    ## Is a component visible, typically used to prevent traversal into the field
    # @returns [true, false] false if components has scrolled off
    def visible? component
      r, c = component.rowcol
      return false if c+@cols_panned < @orig_left
      return false if c+@cols_panned > @orig_left + @display_w
      # XXX TODO for rows UNTESTED for rows
      return false if r + @rows_panned < @orig_top
      return false if r + @rows_panned > @orig_top + @display_h

      return true
    end
    # returns index of first visible component. Currently using column index
    # I am doing this for horizontal scrolling presently
    # @return [index, -1] -1 if none visible, else index/offset
    def first_visible_component_index
      @widgets.each_with_index do |w, ix|
        return ix if visible?(w)
      end
      return -1
    end
    def last_visible_component_index
      ret = -1
      @widgets.each_with_index do |w, ix|
        $log.debug " reverse last vis #{ix} , #{w} : #{visible?(w)} "
        ret = ix if visible?(w)
      end
      return ret
    end
    def req_first_field
      select_field(first_visible_component_index)
    end
    def req_last_field
      select_field(last_visible_component_index)
    end
    def focusable?(w)
      w.focusable and visible?(w)
    end

  end # class ScrollF

  # the return of the prodigals
  # The Expanding Heart
  # The coming together of all those who were


end # module