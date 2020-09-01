class CheckDataMigration
  def initialize(app)
    @app = app
  end

  def call(env)
    if DataMigrate::DataMigrator.needs_migration?
      raise 'Run `rails data:migrate`'
    end
    @app.call(env)
  end
end
