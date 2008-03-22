require 'pathname'
require Pathname(__FILE__).dirname.expand_path + 'spec_helper'
require __DIR__.parent + 'lib/data_mapper/adapters/data_objects_adapter'

module DataMapper
  module Adapters
    class MockAdapter < DataMapper::Adapters::DataObjectsAdapter
      COLUMN_QUOTING_CHARACTER = "`"
      TABLE_QUOTING_CHARACTER = "`"
  
      def delete(instance_or_klass, options = nil)
      end
  
      def save(database_context, instance)
      end
  
      def load(database_context, klass, options)
      end
  
      def table_exists?(name)
        true
      end
  
    end
  end
end