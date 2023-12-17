# settings

This script adds the fastest solution for reading config values - it's based on Struct, not on
OpenStruct nor method_missing, nor defining methods on Object.

No special actions required from other developers or PCs.

## Usage

This script creates example files for configuration. You may change them as you wish!

`config/initializers/settings.rb`:

```ruby
AppConfig = Settings.configurate do
  file("config/settings.yml") # Read one file.
  files("config/settings/*.yml") # Read many files
end
```

If config keys overlap in some files, then the latest loaded file has higher priority.

You may use ".json", ".yml", ".yaml" file extensions.

And anywhere in your code after initialiasing `Settings` you may use Object-like and Hash-like
notations:

```ruby
AppConfig.array_value[0]
AppConfig.hash_value.any_key.nested_key
AppConfig["key with non-valid characters"]
AppConfig[:"key with non-valid characters"]
```

## *.local files

You may prevent saving sensible data into repository.

`config/initializers/settings.rb`:

```ruby
AppConfig = Settings.configurate do
  file("config/settings.yml") # Kept in project repository.
  file("config/settings.local.yml") # Not in project repository.
end
```

`.gitignore`:

```gitignore
config/settings.local.yml
```
