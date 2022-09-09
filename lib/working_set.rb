require 'set'

class WorkingSet
  attr_accessor :name, :search, :options, :items, :note, :saved

  VERSION = "1.1.0"

  def initialize(name: nil, search: nil, options: {}, items: [])
    self.name    = name
    self.search  = search
    self.options = options
    self.items   = []
    items.each { |i| self.add i }
  end

  def add(item)
    if item.kind_of? WorkingSetItem
      items.push item
    else
      items.push WorkingSetItem.new(item)
    end
  end

  def remove(item)
    items.delete item
  end

  def inspect
    str = <<EOS
WorkingSet #{object_id}
Search: #{search}
Options: #{options}
Items:

#{items.map(&:inspect).join("\n")}
EOS
  end

end
