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
      render # have to render to set @scrollable_line_count or the next call won't work
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
    clear_screen
    render_title
    render_items
    refresh_screen
  end

  def toggle_match_lines
    self.show_match_lines = !show_match_lines
    self.scroll_top = 0
    clear_screen
    render
  end

  def select_next_file
    next_file = file_index[selected_item.file_path][:next_file]
    self.selected_item_index = next_file[:item_index] if next_file
    render
  end

  def select_prev_file
    prev_file = file_index[selected_item.file_path][:prev_file]
    self.selected_item_index = prev_file[:item_index] if prev_file
    render
  end

  def select_next_item
    self.selected_item_index += 1 unless selected_item_index >= sorted_items.size - 1
    render
  end

  def select_prev_item
    self.selected_item_index -= 1 unless selected_item_index <= 0
    render
  end

  def scroll(delta)
    return if @scrollable_line_count <= scrollable_height
    set_scroll_top(scroll_top + delta)
    render
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
    Ncurses.LINES - 2
  end

  def scroll_bottom
    scroll_top + scrollable_height
  end

  def render_title
    move 0, 0
    print_field :left, calc_cols(1), " "
    move 0, 0
    color :blue do
      print title
    end

    if needs_save?
      color :red do
        print " +"
      end
    end
  end

  def render_items
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
        print_scrollable_item 0, :blue, "#{item == selected_item ? ">" : " "}" #{item.row}"
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
  end

  def puts_scrollable_item(start_col, color_name, content)
    print_scrollable_item(start_col, color_name, content)
    @scrollable_line_number += 1
  end

  def print_scrollable_item(start_col, color_name, content, *color_content_pairs)
    if scrolled_into_view?(@scrollable_line_number)
      move scrollable_item_line_number_to_screen_row(@scrollable_line_number), start_col
      color color_name do
        printf "%-#{Ncurses.COLS - start_col}s", content
      end
    end
  end

  def scrollable_item_line_number_to_screen_row(line_number)
    line_number - scroll_top + 2
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

  def print_field(align, width, content)
    printf "%#{align == :left ? "-" : ""}#{width}s", content
  end

  def calc_cols(percentage)
    (Ncurses.COLS * percentage).to_i
  end

end
