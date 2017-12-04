/*
 * ----------------------------------------------------------------------------
 * "THE BEER-WARE LICENSE" (Revision 42):
 * <zhukovaa90@gmail.com> wrote this file. As long as you retain this notice you
 * can do whatever you want with this stuff. If we meet some day, and you think
 * this stuff is worth it, you can buy me a beer in return Alexander Zhukov
 * ----------------------------------------------------------------------------
 */

CREATE OR REPLACE FUNCTION install(capacity integer) RETURNS VOID AS $$
BEGIN
    CREATE SEQUENCE IF NOT EXISTS read_ticket  START 0 MINVALUE 0;
    CREATE SEQUENCE IF NOT EXISTS write_ticket START 0 MINVALUE 0;
    CREATE TABLE IF NOT EXISTS queue_params (
        name varchar(64) PRIMARY KEY,
        value integer
    );
    INSERT INTO queue_params (name, value) VALUES
        ('capacity', capacity) ON CONFLICT (name) DO UPDATE SET value=EXCLUDED.value;

    CREATE TABLE IF NOT EXISTS slots (
        id integer PRIMARY KEY,
        turn integer NOT NULL DEFAULT 0,
        value json
    );

    INSERT INTO slots (id, turn)
        SELECT i, i FROM generate_series(0, capacity - 1) AS i
        ON CONFLICT DO NOTHING;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION slot(ticket bigint) RETURNS INT AS $slot$
BEGIN
    RETURN (SELECT ticket & (value - 1) FROM queue_params where name='capacity');
END $slot$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION uninstall() RETURNS VOID as $$
BEGIN
    DROP TABLE IF EXISTS slots, queue_params;
    DROP sequence IF EXISTS read_ticket;
    DROP sequence IF EXISTS write_ticket;
    -- DROP FUNCTION IF EXISTS queue_put(json);
    -- DROP FUNCTION IF EXISTS queue_get();
    -- DROP FUNCTION IF EXISTS slot(bigint);
END
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION queue_put(val json) RETURNS void AS $$
DECLARE
  ticket bigint;
  slot_turn bigint;
  slot_id integer;
BEGIN
    SELECT nextval('write_ticket') INTO ticket;
    SELECT slot(ticket) INTO slot_id;

    LOOP
        SELECT turn from slots where id = slot_id INTO slot_turn;
        IF slot_turn = ticket THEN
            UPDATE slots SET value = val, turn = turn + 1 WHERE id = slot_id;
          RETURN;
        END IF;
    END LOOP;
END;

$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION queue_get() RETURNS json AS $result$
DECLARE
  ticket bigint;
  slot_turn bigint;
  slot_id integer;
  slot_value json;
  capacity integer;
BEGIN

    SELECT nextval('read_ticket') INTO ticket;
    SELECT slot(ticket) INTO slot_id;
    SELECT value FROM queue_params where name = 'capacity' INTO capacity;

    LOOP
        SELECT turn from slots where id = slot_id INTO slot_turn;

        IF slot_turn = ticket + 1 THEN
            UPDATE slots SET turn = ticket + capacity WHERE id = slot_id RETURNING value INTO slot_value;
            RETURN slot_value;
        END IF;
    END LOOP;

END;
$result$ LANGUAGE plpgsql;
