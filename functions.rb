require 'erubi'
require 'json'
require 'yaml'

def cf(save_to, from)
  $main.create_file(save_to, File.read(from))
end

def f(save_to, from)
  cf(save_to, File.join(__dir__, 'templates', from))
end

def af(save_to, from)
  from = File.join(__dir__, 'templates', from)
  $main.append_to_file(save_to, File.read(from))
end

def d(as, from, recursive: false)
  directory = File.join(__dir__, 'templates', from, '*')
  Dir.glob(directory, File::FNM_DOTMATCH).each do |path|
    base_name = File.basename(path)
    next if ['.', '..'].include?(base_name)

    save_to = as.empty? ? base_name : File.join(as, base_name)

    if Dir.exists?(path)
      d(save_to, File.join(from, base_name), recursive: true) if recursive
    else
      cf(save_to, path)
    end
  end
end

def erb(save_to, read_from, **locals)
  b = binding
  locals.each { |k, v| b.local_variable_set(k, v) }

  file_name = File.join(__dir__, 'templates', read_from)

  result = b.eval(Erubi::Engine.new(File.read(file_name)).src)

  $main.create_file(save_to, result)
end

def yaml(save_to, read_from)
  entries = File.exists?(save_to) ? YAML.load(save_to).to_ruby : {}
  append  = File.read(File.join(__dir__, 'templates', read_from))

  entries.deep_merge!(append)

  result = YAML.dump(entries)

  $main.create_file(save_to, result.slice(3, result.length))
end

def remove_strings(file, strings)
  $main.gsub_file(file, /#{strings.join('|')}/m, '')
end

def replace_strings(file, strings)
  $main.gsub_file(file, strings[:from], strings[:to])
end

def css_dir(answers)
  answers[:webpack] ? 'app/javascript/stylesheets' : 'app/assets/stylesheets'
end

$_bundle_commands = []
$_npm_packages    = []
$_npm_commands    = []

def after_bundle_install(&block)
  # if ARGV[0] == 'app:template'
  $_bundle_commands << block
  # else
  # $main.send(:after_bundle, &block)
  # end
end

def add_npm_package(*names)
  $_npm_packages += names
end

def after_npm_install(&block)
  $_npm_commands << block
end

at_exit do
  unless $_bundle_commands.empty?
    $main.send(:bundle_command, 'install', 'BUNDLE_IGNORE_MESSAGES' => '1')
    $_bundle_commands.each(&:call)
  end

  unless $_npm_packages.empty?
    $main.run "yarn add #{$_npm_packages.join(' ')}"
  end
  unless $_npm_commands.empty?
    $_npm_commands.each(&:call)
  end
end
