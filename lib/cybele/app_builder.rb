module Cybele

  class AppBuilder < Rails::AppBuilder

    def readme
      template 'README.md.erb', 'README.md', force: true
    end

    def remove_readme_rdoc
      remove_file 'README.rdoc'
    end

    def replace_gemfile
      remove_file 'Gemfile'
      copy_file 'cybele_Gemfile', 'Gemfile'
    end

    def add_editorconfig
      copy_file 'editorconfig', '.editorconfig'
    end

    def add_ruby_version
      copy_file 'ruby_version', '.ruby_version'
    end

    def add_disable_xml_params
      copy_file 'config/initializers/disable_xml_params.rb', 'config/initializers/disable_xml_params.rb'
    end

    def add_paperclip_aws
      copy_file 'config/initializers/paperclip.rb', 'config/initializers/paperclip.rb'
    end

    def replace_erb_with_haml
      remove_file 'app/views/layouts/application.html.erb'
      template 'app/views/layouts/application.html.haml.erb', 'app/views/layouts/application.html.haml', force: true
    end

    def copy_rake_files
      copy_file 'lib/tasks/annotate.rake', 'lib/tasks/annotate.rake', force: true
    end

    def install_responder_gem
      copy_file 'lib/application_responder.rb', 'lib/application_responder.rb'
      remove_file 'app/controllers/application_controller.rb'
      copy_file 'app/controllers/application_controller.rb', 'app/controllers/application_controller.rb'
      copy_file 'lib/templates/rails/responders_controller/controller.rb', 'lib/templates/rails/responders_controller/controller.rb'
      copy_file 'config/locales/responders.en.yml', 'config/locales/responders.en.yml'
      copy_file 'config/locales/responders.tr.yml', 'config/locales/responders.tr.yml'
    end

    def replace_database_yml
      template 'config/database.yml.erb', 'config/database.yml', force: true
    end

    def create_database
      bundle_command 'exec rake db:create'
    end

    def setup_gitignore_files
      remove_file '.gitignore'
      copy_file 'cybele_gitignore', '.gitignore'
    end

    def setup_gitignore_folders
      %w(
        app/assets/images
        db/migrate
        spec/support
        spec/lib
        spec/models
        spec/views
        spec/controllers
        spec/helpers
      ).each do |dir|
        empty_directory_with_keep_file dir
      end
    end

    def setup_asset_precompile

      config = <<-RUBY


    config.assets.precompile += %w(*.png *.jpg *.jpeg *.gif)
    config.sass.preferred_syntax = :sass
      RUBY

      inject_into_file 'config/application.rb', config, :after => '# config.i18n.default_locale = :de'
    end

    def convert_application_js_to_coffee
      remove_file 'app/assets/javascripts/application.js'
      copy_file 'app/assets/javascripts/application.js.coffee', 'app/assets/javascripts/application.js.coffee'
    end

    def convert_application_css_to_sass
      remove_file 'app/assets/stylesheets/application.css'
      copy_file 'app/assets/stylesheets/application.css.sass', 'app/assets/stylesheets/application.css.sass'
    end

    def configure_smtp
      remove_file 'config/settings/production.yml'
      copy_file 'config/settings/production.yml', 'config/settings/production.yml'
      copy_file 'config/settings/staging.yml', 'config/settings/staging.yml'

      config = <<-RUBY
config.action_mailer.delivery_method = :smtp
config.action_mailer.raise_delivery_errors = false
  config.action_mailer.smtp_settings = Settings.smtp.mandrill
      RUBY

      configure_environment 'production', config
      configure_environment 'staging', config
    end

    def setup_staging_environment
      run 'cp config/environments/production.rb config/environments/staging.rb'

      prepend_file 'config/environments/staging.rb',
                   "Mail.register_interceptor RecipientInterceptor.new(Settings.email.noreply, subject_prefix: '[STAGING]')\n"

      config = <<-YML
email:
  noreply: noreply@appname.org
      YML
      prepend_file 'config/settings.yml', config
    end

    def configure_action_mailer
      action_mailer_host 'development', "#{app_name}.dev"
      action_mailer_host 'test', "#{app_name}.com"
      action_mailer_host 'production', "#{app_name}.com"
    end

    def  setup_letter_opener
      config = 'config.action_mailer.delivery_method = :letter_opener'
      configure_environment 'development', config
    end

    def generate_rspec
      generate 'rspec:install'
    end

    def generate_capybara
      inject_into_file 'spec/spec_helper.rb', :after => "require 'rspec/autorun'" do <<-CODE

require 'capybara/rspec'
      CODE
      end
      inject_into_file 'spec/spec_helper.rb', :after => '  config.order = "random"' do <<-CODE


  # Capybara DSL
  config.include Capybara::DSL
      CODE
      end
    end

    def generate_factory_girl
      inject_into_file 'spec/spec_helper.rb', :after => '  config.include Capybara::DSL' do <<-CODE


  # Factory girl
  config.include FactoryGirl::Syntax::Methods
      CODE
      end
    end

    def generate_simple_form
      generate 'simple_form:install --bootstrap'
      copy_file 'config/locales/simple_form.tr.yml', 'config/locales/simple_form.tr.yml'
      copy_file 'config/locales/tr.yml', 'config/locales/tr.yml'
    end

    def generate_exception_notification
      generate 'exception_notification:install'
    end

    def add_exception_notification_to_environments
      config = <<-CODE

  config.middleware.use ExceptionNotification::Rack,
    :email => {
      :email_prefix => "[Whatever] ",
      :sender_address => %{"notifier" <notifier@example.com>},
      :exception_recipients => %w{exceptions@example.com}
    }
      CODE

      configure_environment('production', config)
      configure_environment('staging', config)
    end

    def leftovers
    end

    def generate_rails_config
      generate 'rails_config:install'
    end

    def generate_devise_settings
      generate 'devise:install'
      gsub_file 'config/initializers/filter_parameter_logging.rb', /:password/, ':password, :password_confirmation'
      gsub_file 'config/initializers/devise.rb', /please-change-me-at-config-initializers-devise@example.com/, 'CHANGEME@example.com'
    end

    def generate_devise_model(model_name)
      generate "devise #{model_name} name:string"
      generate_devise_strong_parameters(model_name)
      remove_file 'config/locales/devise.en.yml'
    end

    def generate_devise_views
      directory 'app/views/devise', 'app/views/devise'
    end

    def generate_welcome_page
      copy_file 'app/controllers/welcome_controller.rb', 'app/controllers/welcome_controller.rb'
      template 'app/views/welcome/index.html.haml.erb', 'app/views/welcome/index.html.haml', force: true
      route "root to: 'welcome#index'"
    end

    def generate_hq_namespace
      generate "devise Admin"
      create_namespace_routing('hq')
      directory 'app/controllers/hq', 'app/controllers/hq'
      #template 'app/views/layouts/hq/base.html.haml.erb', 'app/views/layouts/hq/base.html.haml', force: true
      template 'app/views/hq/dashboard/index.html.haml.erb', 'app/views/hq/dashboard/index.html.haml', force: true
      directory 'app/views/hq/sessions', 'app/views/hq/sessions'
      gsub_file 'config/routes.rb', /devise_for :admins/, "devise_for :admins, controllers: {sessions: 'hq/sessions'}, path: 'hq',
             path_names: {sign_in: 'login', sign_out: 'logout', password: 'secret',
                          confirmation: 'verification'}"
      gsub_file 'app/models/admin.rb', /:registerable,/, ''
    end

    def set_time_zone
      add_set_user_time_zone_method_to_application_controller
      add_time_zone_to_user
    end

    def create_hierapolis_theme
      remove_file 'lib/templates/rails/responders_controller/controller.rb'
      remove_file 'lib/templates/haml/scaffold/_form.html.haml'
      generate 'hierapolis:install'
    end

    def replace_simple_form_wrapper
      remove_file 'config/initializers/simple_form.rb'
      remove_file 'config/initializers/simple_form_bootstrap.rb'

      copy_file 'config/initializers/simple_form.rb', 'config/initializers/simple_form.rb'
      copy_file 'config/initializers/simple_form_bootstrap.rb', 'config/initializers/simple_form_bootstrap.rb'
    end

    def setup_capistrano
      run 'capify .'
    end

    def setup_recipes
      run 'rm config/deploy.rb'
      generate 'recipes_matic:install'
    end

    def update_secret_token
      remove_file 'config/initializers/secret_token.rb'
      template 'config/initializers/secret_token.erb', 'config/initializers/secret_token.rb'
    end

    private

    def action_mailer_host(rails_env, host)

      config = <<-RUBY
# Mail Setting
  config.action_mailer.default_url_options = { :host => '#{host}' }
      RUBY

      configure_environment(rails_env, config)
    end

    def configure_environment(rails_env, config)
      inject_into_file("config/environments/#{rails_env}.rb", "\n\n  #{config}", before: "\nend")
    end

    def generate_devise_strong_parameters(model_name)
      create_sanitizer_lib(model_name)
      create_sanitizer_initializer(model_name)
      devise_parameter_sanitizer(model_name)
    end

    def create_sanitizer_lib(model_name)
      create_file "lib/#{model_name.parameterize}_sanitizer.rb", <<-CODE
class #{model_name.classify}::ParameterSanitizer < Devise::ParameterSanitizer
  private
  def sign_up
    default_params.permit(:name, :email, :password, :password_confirmation, :time_zone) # TODO add other params here
  end
end
      CODE
    end

    def create_sanitizer_initializer(model_name)
      path = "#"
      path << "{Rails.application.root}"
      path << "/lib/#{model_name.parameterize}_sanitizer.rb"
      initializer 'sanitizers.rb', <<-CODE
require "#{path}"
      CODE
    end

    def devise_parameter_sanitizer(model_name)
      inject_into_file 'app/controllers/application_controller.rb', :after => 'protect_from_forgery with: :exception' do <<-CODE

  protected

  def devise_parameter_sanitizer
    if resource_class == #{model_name.classify}
      #{model_name.classify}::ParameterSanitizer.new(#{model_name.classify}, :#{model_name.parameterize}, params)
    else
      super # Use the default one
    end
  end
      CODE
      end
    end

    def create_namespace_routing(namespace)
      inject_into_file 'config/routes.rb', after: "root to: 'welcome#index'" do <<-CODE

  namespace :#{namespace} do
      resources :dashboard, only: [:index]
  end
      CODE
      end
    end

    def add_time_zone_to_user
      say 'Add time_zone to User model'
      generate 'migration AddTimeZoneToUser time_zone:string -s'
    end

    def add_set_user_time_zone_method_to_application_controller
      say 'Add set_user_time_zone method to application controller'
      inject_into_file 'app/controllers/application_controller.rb', :after => 'protected' do <<-CODE

  def set_user_time_zone
    Time.zone = current_user.time_zone if user_signed_in? && current_user.time_zone.present?
  end

      CODE
      end
      inject_into_file 'app/controllers/application_controller.rb', :after => 'class ApplicationController < ActionController::Base' do <<-CODE

  before_filter :set_user_time_zone

      CODE
      end
    end
  end
end
