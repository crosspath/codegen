require 'erubi'
require 'yaml'

def cf(save_to, from)
  # puts "      create    #{save_to}"
  $main.create_file(save_to, File.read(from))
end

def f(save_to, from)
  cf(save_to, File.join(__dir__, 'templates', from))
end

def d(as, from)
  directory = File.join(__dir__, 'templates', from, '*')
  Dir.glob(directory, File::FNM_DOTMATCH).each do |path|
    next if Dir.exists?(path)

    base_name = File.basename(path)
    save_to   = as.empty? ? base_name : File.join(as, base_name)

    cf(save_to, path)
  end
end

def erb(save_to, read_from, **locals)
  b = binding
  locals.each { |k, v| b.local_variable_set(k, v) }

  file_name = File.join(__dir__, 'templates', read_from)

  result = b.eval(Erubi::Engine.new(File.read(file_name)).src)

  # puts "      create    #{save_to}"
  $main.create_file(save_to, result)
end

def yaml(save_to, read_from)
  entries = File.exists?(save_to) ? YAML.load(save_to).to_ruby : {}
  append  = File.read(File.join(__dir__, 'templates', read_from))

  entries.deep_merge!(append)

  result = YAML.dump(entries)

  # puts "      create    #{save_to}"
  $main.create_file(save_to, result.slice(3, result.length))
end
