# frozen_string_literal: true

module Features
  class Sessions < Feature
    register_as "sessions"

    # @param cli [ChangeProject::CLI]
    def initialize(cli)
      super

      @config_application = ConfigApplication.new(cli.app_path)
      @add_gems_for_api_mode = api_mode?
      gemfile_lock = GemfileLock.new(cli.app_path)
      @use_rspec = gemfile_lock.includes?("rspec-core")
      @use_rswag = gemfile_lock.includes?("rswag-specs")
    end

    def call
      puts "Add gems..."
      add_gem("multi_sessions", git: "https://github.com/crosspath/multi-sessions")
      add_gem("jwt", "rack-cors") if @add_gems_for_api_mode

      puts "Change application configs..."
      update_configs
      update_rspec_methods_file if @use_rspec
      update_swagger_helper if @use_rswag
    end

    private

    RSPEC_METHODS = "spec/support/rspec_methods.rb"

    RSPEC_METHODS_FOR_AUTH = <<~RUBY
      def Authorization # rubocop:disable Naming/MethodName
        "Digest \#{@jwt}"
      end

      def sign_in(user = nil)
        # Change these lines if you need.
        user ||= FactoryBot.create(:users_account)
        post users_session_path(email: user.email, password: user.password)

        @jwt = json.dig(:object, :jwt)
        @json = nil
      end
    RUBY

    SWAGGER_AUTH = <<~RUBY.strip.freeze
      components: {securitySchemes: {digest: {name: "Authorization", in: :header, type: :apiKey}}},
    RUBY

    SWAGGER_HELPER = "spec/swagger_helper.rb"

    private_constant :RSPEC_METHODS, :RSPEC_METHODS_FOR_AUTH, :SWAGGER_AUTH, :SWAGGER_HELPER

    def api_mode?
      if @config_application.lines.any? { |line| line.include?("config.api_only = true") }
        return true
      end

      cli.ask.question(
        type: :boolean,
        label: "Add gems for API application",
        default: ->(_, _) { "y" }
      )
    end

    def update_configs
      @config_application.append_to_body(["config.session_store(:disabled)"])

      copy_files_to_project("multi_sessions.rb", "config/initializers/")
      copy_files_to_project("cors.rb", "config/initializers/") if @add_gems_for_api_mode
    end

    def update_rspec_methods_file
      return unless project_file_exist?(RSPEC_METHODS)

      rspec_methods = read_project_file(RSPEC_METHODS).split("\n")
      index = rspec_methods.find_index { |line| line.start_with?("module") }
      raise "Cannot find declaration of module in #{RSPEC_METHODS}" unless index

      new_lines = RSPEC_METHODS_FOR_AUTH.split("\n")

      rspec_methods.insert(index + 1, *StringUtils.indent(new_lines))
    end

    def update_swagger_helper
      swagger_helper = read_project_file(SWAGGER_HELPER).split("\n")
      spec_index = swagger_helper.find_index { |line| line.include?('"v1/swagger.yaml" => {') }
      raise "Cannot find spec definition in #{SWAGGER_HELPER}" unless spec_index

      swagger_helper.insert(spec_index + 1, [SWAGGER_AUTH])
    end
  end
end
