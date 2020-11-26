# frozen_string_literal: true

def sort_gems
  file = File.readlines('Gemfile')

  header = []
  gems   = {all: []} # {:all, ':development', ':development, :test', ...}
  group  = :all

  file.each do |line|
    line.rstrip!
    next if line.empty?
    if line =~ /^\s*gem\s/
      gems[group] << line
    elsif line =~ /^\s*end\s*(\#.*)?$/
      group = :all
    else
      is_group = line.match(/^group\s+(.+)\s+do/)
      if is_group
        group = is_group[1]
        gems[group] ||= []
      else
        header << line
      end
    end
  end

  result = header.join("\n") + "\n"
  result += "\n" + gems[:all].sort.join("\n") + "\n" unless gems[:all].empty?
  gems.delete(:all)

  gems.keys.sort.each do |key|
    unless gems[key].empty?
      result += "\ngroup #{key} do\n" + gems[key].sort.join("\n") + "\nend\n"
    end
  end

  $main.create_file('Gemfile', result)
end

Generator.add_actions do |answers|
  sort_gems
end
