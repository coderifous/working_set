require 'set'

class WorkingSet
  attr_accessor :search, :items, :name, :note, :saved

  VERSION = "1.0.0"

  def initialize(search = nil, items = [])
    self.search = search
    self.items = []
    items.each { |i| self.add i }
  end

  def add(item)
    if item.kind_of? WorkingSetItem
      items.push item
    else
      items.push WorkingSetItem.new(item)
    end
  end

  def inspect
    str = <<EOS
WorkingSet #{object_id}
Search: #{search}
Items:

#{items.map(&:inspect).join("\n")}
EOS
  end

end
