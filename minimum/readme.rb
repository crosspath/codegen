product_name = $main.ask('Название продукта (для Readme) =')

erb(
  'README.md', 'readme/README.md.erb',
  product: product_name
)

f('docs/INSTALL.md', 'readme/INSTALL.md.erb')
f('docs/RELEASE-NOTES.md', 'readme/RELEASE-NOTES.md')
