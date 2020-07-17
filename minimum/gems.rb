puts '      reset required gem versions'
%w[pg puma sass-rails webpacker turbolinks].each do |name|
  $main.gsub_file('Gemfile', /^#[^\n]*\ngem '#{name}'.*$/, "gem '#{name}'")
end

puts '      remove    jbuilder, byebug, web-console'
%w[jbuilder byebug web-console].each do |name|
  $main.gsub_file('Gemfile', /\n\s*#[^\n]*\n\s*gem '#{name}'.*$/, '')
end

$main.gsub_file('Gemfile', "\ngroup :development, :test do\nend\n", '')

$main.gem 'slim-rails'

$main.gem_group :development, :test do
  $main.gem 'dotenv-rails'
end
