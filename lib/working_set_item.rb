class WorkingSetItem
  attr_accessor :file_path, :row, :column, :pinned, :match_line, :pre_match_lines, :post_match_lines

  def initialize(props = {})
    self.file_path        = props[:file_path]
    self.row              = (props[:row]             || 0).to_i
    self.column           = (props[:column]          || 0).to_i
    self.pre_match_lines  = props[:pre_match_lines]  || []
    self.match_line       = props[:match_line]       || ""
    self.post_match_lines = props[:post_match_lines] || []
    self.pinned           = !!props[:pinned]
  end

  def inspect
    str = "#{file_path}\n"
    pre_match_lines.each_with_index do |line, idx|
      str += "#{row - pre_match_lines.size + idx}- #{line}\n"
    end
    str += "#{row}: #{match_line}\n"
    offset = column + row.to_s.length + 1
    str += sprintf "%#{offset}s%s", " ", "^\n"
    post_match_lines.each_with_index do |line, idx|
      str += "#{row + 1 + idx}- #{line}\n"
    end
    str
  end

  def ==(other)
    other &&
      file_path == other.file_path &&
      row == other.row &&
      column == other.column &&
      match_line == other.match_line
  end

  def full_body
    (pre_match_lines + [match_line] + post_match_lines).join("\n")
  end

end
