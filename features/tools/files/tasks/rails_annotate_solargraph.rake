# frozen_string_literal: true

if Rails.env.development?
  namespace :annotate do
    namespace :solargraph do
      desc "Add YARD comments documenting schemas of models"
      task generate: :environment do
        Rails::Annotate::Solargraph.generate
      end

      desc "Remove YARD comments documenting schemas of models"
      task remove: :environment do
        Rails::Annotate::Solargraph.remove
      end
    end

    migration_tasks = %w[
      db:migrate
      db:migrate:down
      db:migrate:redo
      db:migrate:up
      db:prepare
      db:rollback
      db:schema:load
    ]

    migration_tasks.each do |task|
      next unless Rake::Task.task_defined?(task)

      # Invoke this task after migration/rollback.
      Rake::Task[task].enhance { Rake::Task["annotate:solargraph:generate"].invoke }
    end
  end
end
