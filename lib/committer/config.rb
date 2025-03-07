# frozen_string_literal: true

require 'yaml'
require 'fileutils'
require 'singleton'
require_relative 'committer_errors'

module Committer
  # Configuration management for the Committer gem
  class Config
    include Singleton

    CONFIG_DIR = File.join(Dir.home, '.committer')
    CONFIG_FILE = File.join(CONFIG_DIR, 'config.yml')
    DEFAULT_CONFIG = {
      'api_key' => nil,
      'model' => 'claude-3-7-sonnet-20250219',
      'scopes' => nil
    }.freeze

    def initialize
      @config = load_config
    end

    # Accessor for the loaded config
    def [](key)
      @config[key.to_sym] || @config[key.to_s]
    end

    # Get the entire config hash
    def to_h
      @config.dup
    end

    def self.setup
      create_default_config
      puts 'Created config file at:'
      puts CONFIG_FILE
      puts "\nPlease edit this file to add your Anthropic API key."
      puts 'Example config format:'
      puts '---'
      puts 'api_key: your_api_key_here'
      puts 'model: claude-3-7-sonnet-20250219'
      puts 'scopes:'
      puts '  - feature'
      puts '  - api'
      puts '  - ui'
    end

    def self.create_default_config
      FileUtils.mkdir_p(CONFIG_DIR)
      File.write(CONFIG_FILE, DEFAULT_CONFIG.to_yaml)
    end

    def load_config
      # Load configs from both locations and merge them
      home_config = load_config_from_path(CONFIG_FILE)
      git_root_config = load_config_from_git_root
      raise Committer::ConfigErrors::NotSetup if home_config.empty? && git_root_config.empty?

      # Merge configs with git root taking precedence
      home_config.merge(git_root_config)
    end

    def load_config_from_path(path)
      return {} unless File.exist?(path)

      result = YAML.load_file(path)
      raise Committer::ConfigErrors::FormatError, 'Config file must be a YAML hash' unless result.is_a?(Hash)

      result
    end

    def load_config_from_git_root
      git_root = `git rev-parse --show-toplevel`.strip
      return {} if git_root.empty?

      git_config_file = File.join(git_root, '.committer', 'config.yml')
      load_config_from_path(git_config_file)
    rescue StandardError
      {}
    end

    # Force reload configuration (useful for testing)
    def reload
      @config = load_config
    end

    # Class method for reload
    def self.reload
      instance.reload
    end
  end
end
