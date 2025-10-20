class AddListUpdateTrigger < ActiveRecord::Migration[8.0]
  def change
    safety_assured {
      execute <<~SQL
        CREATE OR REPLACE FUNCTION notify_lists_changed() RETURNS trigger AS $$
        BEGIN
          PERFORM pg_notify(
            'lists_changed',
            json_build_object(
              'table', TG_TABLE_NAME,
              'action', TG_OP
            )::text
          );
          RETURN NULL;
        END;
        $$ LANGUAGE plpgsql;
      SQL
    }

    safety_assured {
      execute <<~SQL
        DROP TRIGGER IF EXISTS lists_changed_trigger ON lists;
        CREATE TRIGGER lists_changed_trigger
        AFTER INSERT OR UPDATE OR DELETE ON lists
        FOR EACH STATEMENT
        EXECUTE FUNCTION notify_lists_changed();
      SQL
    }
  end
end
