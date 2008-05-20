gem 'do_mysql', '=0.9.0'
require 'do_mysql'

module DataMapper
  module Adapters

    # Options:
    # host, user, password, database (path), socket(uri query string), port
    class MysqlAdapter < DataObjectsAdapter

      # TypeMap for MySql databases.
      #
      # @return <DataMapper::TypeMap> default TypeMap for MySql databases.
      def self.type_map
        @type_map ||= TypeMap.new(super) do |tm|
          tm.map(Fixnum).to('INT').with(:size => 11)
          tm.map(TrueClass).to('TINYINT').with(:size => 1)  # TODO: map this to a BIT or CHAR(0) field?
          tm.map(Object).to('TEXT')
        end
      end

      # TODO: move to dm-more/dm-migrations (if possible)
      def storage_exists?(storage_name)
        statement = <<-EOS.compress_lines
          SELECT COUNT(*)
          FROM `information_schema`.`columns`
          WHERE `table_schema` = ? AND `table_name` = ?
        EOS

        query(statement, db_name, storage_name).first > 0
      end
      alias exists? storage_exists?

      # TODO: move to dm-more/dm-migrations (if possible)
      def field_exists?(storage_name, field_name)
        statement = <<-EOS.compress_lines
          SELECT COUNT(*)
          FROM `information_schema`.`columns`
          WHERE `table_schema` = ? AND `table_name` = ? AND `column_name` = ?
        EOS

        query(statement, db_name, storage_name, field_name).first > 0
      end

      private

      # TODO: move to dm-more/dm-migrations (if possible)
      def db_name
        @uri.path.split('/').last
      end

      module SQL
        private

        def supports_default_values?
          false
        end

        def quote_table_name(table_name)
          "`#{table_name.gsub('`', '``')}`"
        end

        def quote_column_name(column_name)
          "`#{column_name.gsub('`', '``')}`"
        end

        def quote_column_value(column_value)
          case column_value
            when TrueClass  then quote_column_value(1)
            when FalseClass then quote_column_value(0)
            else
              super
          end
        end

        # TODO: move to dm-more/dm-migrations
        def supports_autoincrement?
          true
        end

        # TODO: move to dm-more/dm-migrations
        def create_table_statement(model)
          character_set = show_variable('character_set_connection') || 'utf8'
          collation     = show_variable('collation_connection')     || 'utf8_general_ci'
          "#{super} ENGINE = InnoDB CHARACTER SET #{character_set} COLLATE #{collation}"
        end

        # TODO: move to dm-more/dm-migrations
        def property_schema_hash(property, model)
          schema = super
          schema.delete(:default) if schema[:primitive] == 'TEXT'
          schema
        end

        # TODO: move to dm-more/dm-migrations
        def property_schema_statement(schema)
          statement = super
          statement << ' AUTO_INCREMENT' if schema[:serial?] && supports_autoincrement?
          statement
        end

        # TODO: move to dm-more/dm-migrations
        def show_variable(name)
          query('SHOW VARIABLES WHERE `variable_name` = ?', name).first.value rescue nil
        end
      end #module SQL

      include SQL

    end # class MysqlAdapter
  end # module Adapters
end # module DataMapper
