def webpack_bundle
  $main.run 'yarn add webpack-bundle-analyzer --dev'

  $main.inject_into_file(
    'config/webpack/production.js',
    before: 'module.exports = environment.toWebpackConfig()'
  ) do
    <<-END
// Run `NODE_ENV=production DIAGRAM=1 bin/webpack`
// when you want to see volumes of JS packs.
if (process.env.DIAGRAM) {
  const { BundleAnalyzerPlugin } = require('webpack-bundle-analyzer');
  environment.plugins.append('BundleAnalyzer', new BundleAnalyzerPlugin());
}

    END
  end
end

def webpack_comment
  replace_strings(
    'config/webpacker.yml',
    {
      from:
          "  # Production depends on precompilation of packs prior to "\
          "booting for performance.",
      to:
          "  # Production depends on precompilation of packs prior to "\
          "booting\n"\
          "  # for performance."
    }
  )
  remove_strings(
    'app/javascript/packs/application.js',
    [
      "// This file is automatically compiled by Webpack, along with any "\
          "other files\n"\
          "// present in this directory. You're encouraged to place your "\
          "actual application logic in\n"\
          "// a relevant structure within app/javascript and only use these "\
          "pack files to reference\n"\
          "// that code so it'll be compiled.\n\n"
    ]
  )

  replace_strings(
    'app/javascript/packs/application.js',
    {
      from:
          "\n// Uncomment to copy all static images under ../images to "\
          "the output folder and reference\n"\
          "// them with the image_pack_tag helper in views (e.g "\
          "<%= image_pack_tag 'rails.png' %>)\n"\
          "// or the `imagePath` JavaScript helper below.",
      to:
          "// Uncomment to copy all static images under ../images to "\
          "the output folder\n"\
          "// and reference them with the image_pack_tag helper in views\n"\
          "// (e.g <%= image_pack_tag 'rails.png' %>)\n"\
          "// or the `imagePath` JavaScript helper below.",
    }
  )
end

Generator.add_actions do |answers|
  next unless answers[:webpack]

  after_bundle_install do
    $main.rails_command 'webpacker:install'

    webpack_bundle
    webpack_comment
  end
end
