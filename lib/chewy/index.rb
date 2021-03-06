require 'chewy/index/actions'
require 'chewy/index/aliases'
require 'chewy/index/search'

module Chewy
  class Index
    include Actions
    include Aliases
    include Search

    singleton_class.delegate :client, to: 'Chewy'

    class_attribute :type_hash
    self.type_hash = {}

    class_attribute :_settings
    self._settings = {}

    def self.define_type(name_or_scope, &block)
      type_class = Chewy::Type.new(self, name_or_scope, &block)
      self.type_hash = type_hash.merge(type_class.type_name => type_class)

      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def self.#{type_class.type_name}
          type_hash['#{type_class.type_name}']
        end
      RUBY
    end

    def self.types *args
      if args.any?
        all.types *args
      else
        type_hash.values
      end
    end

    def self.type_names
      type_hash.keys
    end

    def self.settings(params)
      self._settings = params
    end

    def self.index_name(suggest = nil)
      if suggest
        @index_name = suggest.to_s
      else
        @index_name ||= (name.gsub(/Index\Z/, '').demodulize.underscore if name)
      end
      @index_name or raise UndefinedIndex
    end

    def self.build_index_name options = {}
      [index_name, options[:suffix]].reject(&:blank?).join(?_)
    end

    def self.settings_hash
      _settings.present? ? {settings: _settings} : {}
    end

    def self.mappings_hash
      mappings = types.map(&:mappings_hash).inject(:merge)
      mappings.present? ? {mappings: mappings} : {}
    end

    def self.index_params
      [settings_hash, mappings_hash].inject(:merge)
    end

    def self.search_index
      self
    end

    def self.search_type
      type_names
    end

    def self.import options = {}
      types.all? { |t| t.import options }
    end
  end
end
