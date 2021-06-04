class CheckDataMigration
  def initialize(app)
    @app = app
  end

  def call(env)
    raise 'Run `rails data:migrate`' if DataMigrate::DataMigrator.needs_migration?
    @app.call(env)
  end
end
