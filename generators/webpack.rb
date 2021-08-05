def webpack_bundle
  $main.run 'yarn add webpack-bundle-analyzer --dev'

  $main.inject_into_file(
    'config/webpack/production.js',
    before: 'module.exports = environment.toWebpackConfig()'
  ) do
    <<-END
// Run `NODE_ENV=production DIAGRAM=1 bin/webpack` when you want to see volumes of JS packs.
if (process.env.DIAGRAM) {
  const { BundleAnalyzerPlugin } = require('webpack-bundle-analyzer');
  environment.plugins.append('BundleAnalyzer', new BundleAnalyzerPlugin());
}

    END
  end
end

def webpack_comment
  remove_strings(
    'app/javascript/packs/application.js',
    [
      "// This file is automatically compiled by Webpack, along with any other files\n"\
          "// present in this directory. You're encouraged to place your "\
          "actual application logic in\n"\
          "// a relevant structure within app/javascript and only use these "\
          "pack files to reference\n"\
          "// that code so it'll be compiled.\n\n"
    ]
  )
end

def webpack_css(answers)
  if answers[:design]
    $main.append_to_file(
      'app/javascript/stylesheets/application.scss',
      "@import './components/flash.scss';\n"
    )
  end

  $main.append_to_file(
    'app/javascript/packs/application.js',
    "import '../stylesheets/application.scss';\n"
  )
end

Generator.add_actions do |answers|
  next unless answers[:webpack]

  after_bundle_install do
    unless `bundle info webpacker`.include?('Summary')
      $main.rails_command 'webpacker:install'
    end

    webpack_bundle
    webpack_comment
    webpack_css(answers)
  end
end
