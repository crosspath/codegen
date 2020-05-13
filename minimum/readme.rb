require 'bundler'

product_name = $main.ask('Название продукта (для Readme) =')

erb(
  'README.md', 'readme/README.md.erb',
  product: product_name
)

erb(
  'INSTALL.md', 'readme/INSTALL.md.erb',
  ruby:    RUBY_VERSION,
  bundler: Bundler::VERSION
)
