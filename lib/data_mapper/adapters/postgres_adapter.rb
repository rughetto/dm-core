gem 'do_postgres', '=0.9.0'
require 'do_postgres'

module DataMapper
  module Adapters

    class PostgresAdapter < DataObjectsAdapter

      # TypeMap for PostgreSQL databases.
      #
      # @return <DataMapper::TypeMap> default TypeMap for PostgreSQL databases.
      def self.type_map
        @type_map ||= TypeMap.new(super) do |tm|
          tm.map(DateTime).to('TIMESTAMP')
          tm.map(Fixnum).to('INT4')
          tm.map(Float).to('FLOAT8')
        end
      end

      # TODO: move to dm-more/dm-migrations (if possible)
      def storage_exists?(storage_name)
        statement = <<-EOS.compress_lines
          SELECT COUNT(*)
          FROM "information_schema"."columns"
          WHERE "table_name" = ? AND "table_schema" = current_schema()
        EOS

        query(statement, storage_name).first > 0
      end
      alias exists? storage_exists?

      # TODO: move to dm-more/dm-migrations (if possible)
      def field_exists?(storage_name, column_name)
        statement = <<-EOS.compress_lines
          SELECT COUNT(*)
          FROM "pg_class"
          JOIN "pg_attribute" ON "pg_class"."oid" = "pg_attribute"."attrelid"
          WHERE "pg_attribute"."attname" = ? AND "pg_class"."relname" = ? AND "pg_attribute"."attnum" >= 0
        EOS

        query(statement, column_name, storage_name).first > 0
      end

      # TODO: move to dm-more/dm-migrations
      def upgrade_model_storage(repository, model)
        storage_name = model.storage_name(name)
        model.key.each do |property|
          schema_hash = property_schema_hash(property, model)
          create_sequence_column(model, property) if property.serial? && !field_exists?(storage_name, schema_hash[:name])
        end
        super
      end

      # TODO: move to dm-more/dm-migrations
      def create_model_storage(repository, model)
        model.key.each do |property|
          create_sequence_column(model, property) if property.serial?
        end
        super
      end

      # TODO: move to dm-more/dm-migrations
      def destroy_model_storage(repository, model)
        success = super
        model.key.each do |property|
          drop_sequence_column(model, property) if property.serial?
        end
        success
      end

      module SQL
        protected

        # TODO: move to dm-more/dm-migrations
        def create_sequence_column(model, property)
          return if sequence_exists?(model, property)
          execute(create_sequence_statement(model, property))
        end

        # TODO: move to dm-more/dm-migrations
        def drop_sequence_column(model, property)
          execute(drop_sequence_statement(model, property))
        end

        private

        def supports_returning?
          true
        end

        # TODO: move to dm-more/dm-migrations
        def sequence_name(model, property)
          "#{model.storage_name(name)}_#{property.field}_seq"
        end

        # TODO: move to dm-more/dm-migrations
        def sequence_exists?(model, property)
          statement = <<-EOS.compress_lines
            SELECT COUNT(*)
            FROM "pg_class"
            WHERE "relkind" = 'S' AND "relname" = ?
          EOS

          query(statement, sequence_name(model, property)).first > 0
        end

        # TODO: move to dm-more/dm-migrations
        def create_sequence_statement(model, property)
          "CREATE SEQUENCE #{quote_column_name(sequence_name(model, property))}"
        end

        # TODO: move to dm-more/dm-migrations
        def drop_sequence_statement(model, property)
          "DROP SEQUENCE IF EXISTS #{quote_column_name(sequence_name(model, property))}"
        end

        # TODO: move to dm-more/dm-migrations
        def property_schema_statement(schema)
          statement = super

          if schema.has_key?(:sequence_name)
            statement << " DEFAULT nextval('#{schema[:sequence_name]}') NOT NULL"
          end

          statement
        end

        # TODO: move to dm-more/dm-migrations
        def property_schema_hash(property, model)
          schema = super
          schema[:sequence_name] = sequence_name(model, property) if property.serial?

          # TODO: see if TypeMap can be updated to set specific attributes to nil
          # for different adapters.  scale/precision are perfect examples for
          # Postgres floats

          # Postgres does not support scale and precision for Float
          if property.primitive == Float
            schema.delete(:scale)
            schema.delete(:precision)
          end

          schema
        end
      end #module SQL

      include SQL

    end # class PostgresAdapter

  end # module Adapters
end # module DataMapper
