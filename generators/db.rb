Generator.add_actions do |answers|
  erb(
    'config/database.yml', 'config/database.yml.erb',
    use_url: answers[:db],
    db_name: answers[:db_name] || ''
  )
end
