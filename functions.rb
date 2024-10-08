require 'erubi'
require 'json'
require 'yaml'

def f(save_to, from)
  cf(save_to, File.join(__dir__, 'templates', from))
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

def remove_strings(file, strings)
  pattern = Regexp.new('[]{}()<>#$^*-+?'.each_char.map { |x| "\\#{x}" }.join('|'))
  strings = strings.map do |str|
    if str.is_a?(Regexp)
      str
    else
      str.gsub(pattern) { |x| "\\#{x}" }
    end
  end
  $main.gsub_file(file, /#{strings.join('|')}/m, '') if File.exist?(file)
end

def replace_strings(file, strings)
  $main.gsub_file(file, strings[:from], strings[:to]) if File.exist?(file)
end

def css_dir(answers)
  'app/assets/stylesheets'
end

def empty_dir?(directory)
  entries = Dir.glob("#{directory}/*", flags: File::FNM_DOTMATCH)
  except  = %w[. .. .keep].map { |x| "#{directory}/#{x}" }
  (entries - except).empty?
end

$_bundle_commands = []
$_npm_packages    = []

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

at_exit do
  unless $_bundle_commands.empty?
    $main.send(:bundle_command, 'install', 'BUNDLE_IGNORE_MESSAGES' => '1')
    $_bundle_commands.each(&:call)
  end

  unless $_npm_packages.empty?
    $main.run "yarn add #{$_npm_packages.join(' ')}"
  end
end
