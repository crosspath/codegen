Generator.add_actions do |answers|
  next unless answers[:product]

  erb(
    'README.md', 'readme/README.md.erb',
    product: answers[:product_name]
  )

  f('docs/INSTALL.md', 'readme/INSTALL.md')
  f('docs/RELEASE-NOTES.md', 'readme/RELEASE-NOTES.md')

  if answers[:product_specs]
    d('docs', 'docs')
    af('README.md', 'docs/README.md')
  end
end
