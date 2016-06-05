require 'open3'

module SetBuilderAdapter
  class Ag

    class ParserError < StandardError; end

    class Parser
      attr_accessor :input, :parsed_items, :current_item

      def initialize(input)
        self.input = input
        self.parsed_items = []
      end

      def parse
        input.split("\n").each do |line|
          parse_line line
        end
        record_existing_item
        parsed_items
      end

      def learn(key, value)
        self.current_item[key] = value
      end

      def add(list_key, value)
        self.current_item[list_key] ||= []
        self.current_item[list_key].push value
      end

      def record_existing_item
        if current_item
          parsed_items << current_item
        end
      end

      def new_item_with_file_path(file_path)
        record_existing_item
        self.current_item = { }
        learn :file_path, file_path
      end

      def parse_line(line)
        # A new item is started when the current item has no path, or if the
        # path for the current result line doesn't match the current item's file
        # path.
        if current_item == nil or (line != "--" and line != "" and not line.start_with?(current_item[:file_path]))
          line =~ /^(.*?):\d/
          new_item_with_file_path $1
        end

        # The line can be either a pre or post match for the current item
        if line =~ /^(.*?):(\d+)-(.*)/
          if current_item[:match_line]
            add :post_match_lines, $3
          else
            add :pre_match_lines, $3
          end

        # The line can be the actual match itself
        elsif line =~ /^(.*?):(\d+):(\d+):(.*)/ # match line
          if current_item[:match_line]
            new_item_with_file_path current_item[:file_path]
          end
          learn :row, $2
          learn :column, $3
          learn :match_line, $4

        # Finally, the item can be the inter-file match separator
        elsif line =~ /--/
          new_item_with_file_path current_item[:file_path]

        # Weird exception: a blank line will be ignored.
        elsif line == ""

        # Otherwise big fat fail.
        else
          raise ParserError.new("parse_line failed for: #{line.inspect}")
        end
      end

    end

    def command(search)
      "ag -C1 --line-numbers --column --nogroup --literal #{search} ."
    end

    def parse_results(results)
      Parser.new(results).parse
    rescue ParserError => e
      STDERR.puts e
      raise e
    end

    def build_working_set(search)
      # stdout, stderr, status = Open3.capture3(command(search))
      # if status == 0
      stdout = `#{command(search)}`
      if $?.exitstatus == 0 || $?.exitstatus == 1
        WorkingSet.new search, parse_results(stdout)
      else
        # raise "ag command failed: #{stdout} #{stderr}"
        raise "ag command failed with status #{$?.exitstatus.inspect}: #{stdout}"
      end
    end

  end
end
