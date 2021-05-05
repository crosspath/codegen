Generator.add_actions do |answers|
  next unless answers[:product]

  erb(
    'README.md', 'readme/README.md.erb',
    product: answers[:product_name],
    design:  answers[:design],
    css_dir: css_dir(answers),
    specs:   answers[:product_specs],
    deploy:  answers[:capistrano]
  )

  f('docs/INSTALL.md', 'readme/INSTALL.md')
  f('docs/RELEASE-NOTES.md', 'readme/RELEASE-NOTES.md')

  if answers[:product_specs]
    d('docs', 'docs')
  end
end
