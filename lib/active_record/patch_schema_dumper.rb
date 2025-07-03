# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module PostgreSQL
      class SchemaDumper < ConnectionAdapters::SchemaDumper
        private

        def schemas(stream)
          schema_names = @connection.schema_names - ['public', 'pgroonga']

          if schema_names.any?
            schema_names.sort.each do |name|
              stream.puts "  create_schema #{name.inspect}"
            end
            stream.puts
          end
        end
      end
    end
  end
end
