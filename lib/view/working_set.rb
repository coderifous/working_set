# +--------------------------------------------------------------------------+
# | Search or Working Set Name + (indicates dirty/saved state)             |
# +--------------------------------------------------------------------------+
# | Note if present                                                          |
# +--------------------------------------------------------------------------+
# |                                                                          |
# | app/models/foo.rb                                                        |
# |   10 def foo                                                             |
# | > 11   puts "bar" (highlight match)                                      |
# |   12 end                                                                 |
# |                                                                          |
# | app/models/bar.rb                                                        |
# |   10 def bar                                                             |
# |   11   puts "foo" (highlight match)                                      |
# |   12 end                                                                 |
# |                                                                          |
# |   10 def bar                                                             |
# |   11   puts "foo" (highlight match)                                      |
# |   12 end                                                                 |
# +--------------------------------------------------------------------------+
# |                                                         1-10 of 16 items |
# +--------------------------------------------------------------------------+
#
# * Highlight "selected item" with colors.

class View::WorkingSet < View::Base
  attr_accessor :working_set, :selected_item_index, :file_index, :scroll_top, :scrollable_height, :show_match_lines

  TITLE_ROWS  = 2
  FOOTER_ROWS = 3

  def self.render(working_set)
    new(working_set).render
  end

  def initialize(working_set)
    self.working_set = working_set
    self.file_index = index_files(working_set)
    self.selected_item_index = 0
    self.scroll_top = 0
    self.show_match_lines = true
  end

  def index_files(working_set)
    index = {}
    prev_file = nil
    sorted_items.each_with_index do |item, idx|
      if prev_file == nil
        # first item in set
        prev_file = index[item.file_path] = { file_path: item.file_path, item_index: idx, prev_file: nil }
      elsif item.file_path == prev_file[:file_path]
        # another match within file, ignore it.
      else
        # next file
        current_file = index[item.file_path] = { file_path: item.file_path, item_index: idx, prev_file: prev_file }
        prev_file[:next_file] = current_file
        prev_file = current_file
      end
    end
    index
  end

  def selected_item
    sorted_items[selected_item_index]
  end

  def restore_selection_state(from_working_set_view)
    if idx = sorted_items.find_index(from_working_set_view.selected_item)
      self.selected_item_index = idx
      self.show_match_lines    = from_working_set_view.show_match_lines
      render_items_and_footer # have to render to set @scrollable_line_count or the next call won't work
      set_scroll_top(from_working_set_view.scroll_top)
    end
  end

  def title
    if working_set.name
      "Name: #{working_set.name}"
    else
      "Search: #{working_set.search}"
    end
  end

  def note
    working_set.note
  end

  def needs_save?
    !working_set.saved
  end

  def sorted_items
    @_sorted_items ||= working_set.items.sort_by { |i| [i.file_path, i.row.to_i]  }
  end

  def render
    UserInputActor.set_user_input_mode :working_set
    stdscr.clear
    stdscr.refresh
    render_title.refresh
    render_items.refresh
    render_footer.refresh
  end

  def toggle_match_lines
    self.show_match_lines = !show_match_lines
    self.scroll_top = 0
    @item_win.clear
    render_items.refresh
  end

  def render_items_and_footer
    render_items.refresh
    render_footer.refresh
  end

  def select_next_file
    next_file = file_index[selected_item.file_path][:next_file]
    self.selected_item_index = next_file[:item_index] if next_file
    render_items_and_footer
  end

  def select_prev_file
    prev_file = file_index[selected_item.file_path][:prev_file]
    self.selected_item_index = prev_file[:item_index] if prev_file
    render_items_and_footer
  end

  def select_next_item
    self.selected_item_index += 1 unless selected_item_index >= sorted_items.size - 1
    render_items_and_footer
  end

  def select_prev_item
    self.selected_item_index -= 1 unless selected_item_index <= 0
    render_items_and_footer
  end

  def delete_selected_item
    working_set.remove(selected_item)
    items_changed!
    if selected_item.nil?
      self.selected_item_index -= 1 if selected_item_index > 0
    end
    # render_items_and_footer
    render
  end

  def scroll(delta)
    return if @scrollable_line_count <= scrollable_height
    set_scroll_top(scroll_top + delta)
    render_items_and_footer
  end

  def set_scroll_top(value)
    self.scroll_top = if value < 2
                        # Reached top
                        0
                      elsif (value + scrollable_height) > @scrollable_line_count
                        # Reached bottom
                        [@scrollable_line_count - scrollable_height, 0].max
                      else
                        # Normal scroll
                        value
                      end
  end

  def scrollable_height
    Ncurses.LINES - TITLE_ROWS - FOOTER_ROWS
  end

  def scroll_bottom
    scroll_top + scrollable_height
  end

  def render_title
    # Height, Width, Y, X   note: (0 width == full width)
    @title_win ||= Ncurses.newwin(1, 0, 0, 0)
    @title_win.move 0, 0
    print_field @title_win, :left, calc_cols(1), " "
    @title_win.move 0, 0
    with_color @title_win, :blue do
      @title_win.printw title
    end
    if working_set.options["whole_word"]
      with_color @title_win, :red do
        @title_win.printw " [w]"
      end
    end
    # if needs_save?
    #   with_color @title_win, :red do
    #     @title_win.printw " +"
    #   end
    # end
    @title_win
  end

  def render_footer
    # Height, Width, Y, X   note: (0 width == full width)
    height = FOOTER_ROWS - 1
    @footer_win ||= Ncurses.newwin(height, 0, Ncurses.LINES - height, 0)
    @footer_win.move 0, 0
    with_color @footer_win, :blue do
      history = $supervisor[:set_history]
      prev_term = history.peek_search_term_back
      next_term = history.peek_search_term_forward
      history_msg = [].tap do |a|
        a << "< #{prev_term}" if prev_term
        a << "#{next_term} >" if next_term
      end
      print_field @footer_win, :left,  calc_cols(1), history_msg.join(" | ")
      print_field @footer_win, :left,  calc_cols(0.5), "Search History #{history.position + 1} of #{history.entries.size}"
      print_field @footer_win, :right, calc_cols(0.5), "#{selected_item_index + 1} of #{sorted_items.size} (#{file_index.keys.size} files)"
    end
    @footer_win
  end

  def render_items

    # Height, Width, Y, X   note: (0 width == full width)
    @item_win ||= Ncurses.newwin(scrollable_height, 0, TITLE_ROWS, 0)

    previous_file_path      = nil
    previous_row            = 0
    @scrollable_line_number = 0
    @scrollable_line_count  = 0

    sorted_items.each do |item|

      if !show_match_lines
        if item.file_path != previous_file_path
          color = item.file_path == selected_item.file_path ? :cyan : :green
          puts_scrollable_item 0, color, item.file_path
        end
      else
        # Print file name if it's a new file, a "--" separator if it's the same
        # file but non-consecutive lines, otherwise just nothing.
        if item.file_path == previous_file_path
          if item.row > previous_row + 1
            puts_scrollable_item 0, :white, "  --"
          end
        else
          if previous_file_path
            puts_scrollable_item 0, :white, ""
          end
          color = item.file_path == selected_item.file_path ? :cyan : :green
          puts_scrollable_item 0, color, item.file_path
        end

        # Print pre-match lines.
        item.pre_match_lines.each_with_index do |line, i|
          print_scrollable_item 0, :white, "  #{item.row - item.pre_match_lines.size + i}"
          puts_scrollable_item 5, :white, line
        end

        # Record match line number
        if item == selected_item
          @selected_item_line_number = @scrollable_line_number
        end

        # Print match line.
        print_scrollable_item 0, :blue, "#{item == selected_item ? ">" : " "}"
        print_scrollable_item 2, :yellow, item.row
        puts_scrollable_item 5, :yellow, item.match_line

        # Print post-match lines.
        item.post_match_lines.each_with_index do |line, i|
          print_scrollable_item 0, :white, "  #{item.row + 1 + i}"
          puts_scrollable_item 5, :white, line
        end
      end

      previous_file_path = item.file_path
      previous_row       = item.row + item.post_match_lines.size
    end

    @scrollable_line_count = @scrollable_line_number

    @item_win
  end

  def puts_scrollable_item(start_col, color_name, content)
    print_scrollable_item(start_col, color_name, content)
    @scrollable_line_number += 1
  end

  def print_scrollable_item(start_col, color_name, content, *color_content_pairs)
    if scrolled_into_view?(@scrollable_line_number)
      y = scrollable_item_line_number_to_screen_row(@scrollable_line_number)
      x = start_col
      with_color @item_win, color_name do
        @item_win.mvprintw y, x, "%-#{Ncurses.COLS - start_col}s", content
      end
    end
  end

  def scrollable_item_line_number_to_screen_row(line_number)
    line_number - scroll_top
  end

  def scrolled_into_view?(line_number, context_lines: 0)
    result = (line_number - context_lines) >= scroll_top && (line_number + context_lines) < scroll_bottom
    debug_message "scrolled_into_view line_number: #{line_number} context_lines: #{context_lines} result: #{result.inspect}"
    result
  end

  def selected_item_in_view?
    scrolled_into_view? @selected_item_line_number, context_lines: $CONTEXT_LINES
  end

  def selected_item_scroll_delta
    scroll_padding = 2 + $CONTEXT_LINES
    debug_message "scrolling #{@selected_item_line_number} | #{scroll_top} | #{scroll_bottom}"
    if scroll_top > (@selected_item_line_number - $CONTEXT_LINES)
      # scroll up
      ((scroll_top - @selected_item_line_number) * -1) - scroll_padding
    elsif scroll_bottom < (@selected_item_line_number + $CONTEXT_LINES)
      # scroll down
      @selected_item_line_number - scroll_bottom + scroll_padding
    else
      0
    end
  end

  def print_field(window, align, width, content)
    window.printw "%#{align == :left ? "-" : ""}#{width}s", content
  end

  def calc_cols(percentage)
    (Ncurses.COLS * percentage).to_i
  end

  private

  def items_changed!
    @_sorted_items = nil
    self.file_index = index_files(working_set)
  end

end
