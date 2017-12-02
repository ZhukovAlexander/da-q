/*
 * ----------------------------------------------------------------------------
 * "THE BEER-WARE LICENSE" (Revision 42):
 * <zhukovaa90@gmail.com> wrote this file. As long as you retain this notice you
 * can do whatever you want with this stuff. If we meet some day, and you think
 * this stuff is worth it, you can buy me a beer in return Alexander Zhukov
 * ----------------------------------------------------------------------------
 */

CREATE SEQUENCE IF NOT EXISTS read_ticket;
CREATE SEQUENCE IF NOT EXISTS write_ticket;

CREATE TABLE IF NOT EXISTS slots (
	id integer PRIMARY KEY CHECK (id < 64),  -- just hardcode for POC
	turn integer NOT NULL,
	value json
);

CREATE OR REPLACE FUNCTION put(val json) RETURNS void AS $$
DECLARE
  ticket bigint;
  turn bigint;
  slot_id integer;
  BEGIN
    SELECT nextval('read_ticket') INTO ticket;
    SELECT (ticket % 3) INTO slot_id;

    LOOP
    -- some computations
        SELECT turn from slots where id=slot_id INTO turn;
        IF turn=ticket THEN
            UPDATE slots SET value=val WHERE id=slot_id;
            EXIT;  -- exit loop
        END IF;
    END LOOP;
    RETURN;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get() RETURNS void AS $$
DECLARE
  ticket bigint;
  turn bigint;
  slot_id integer;
  value json;
BEGIN

    SELECT nextval('write_ticket') INTO ticket;
    SELECT (ticket % 3) INTO slot_id;

    LOOP
    -- some computations
        SELECT turn from slots where id=slot_id INTO turn;
        IF turn=ticket THEN
            EXIT;  -- exit loop
        END IF;
    END LOOP;

    LOOP
    -- some computations
        SELECT value from slots where id=slot_id INTO value;
        IF value != null THEN
            UPDATE slots SET value=null, turn=turn+3+1 WHERE id=slot_id;
            EXIT;  -- exit loop
        END IF;
    END LOOP;
    RETURN;
END;
$$ LANGUAGE plpgsql;


