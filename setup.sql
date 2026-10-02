-- Set up both demo apps in Streamlit in Snowflake.
--
-- Run from the repo root so the file:// paths resolve:
--   snow sql -f setup.sql
--
-- Replace these placeholders before you run it:
--   MY_DB.MY_SCHEMA               database and schema for the table, stage and apps
--   MY_WAREHOUSE                  query warehouse
--   MY_COMPUTE_POOL               compute pool for the container runtime
--   MY_PYPI_ACCESS_INTEGRATION    external access integration that allows PyPI

USE SCHEMA MY_DB.MY_SCHEMA;
USE WAREHOUSE MY_WAREHOUSE;

-- 1. Load the sample data into USER_EVENTS_DEMO.
CREATE OR REPLACE TABLE USER_EVENTS_DEMO (
  EVENT_DATE DATE,
  USER_ID    VARCHAR,
  REGION     VARCHAR,
  CHANNEL    VARCHAR,
  REVENUE    NUMBER
);

CREATE STAGE IF NOT EXISTS ST_CACHING_STAGE;

PUT file://data/user_events.csv @ST_CACHING_STAGE/data AUTO_COMPRESS = FALSE OVERWRITE = TRUE;

COPY INTO USER_EVENTS_DEMO
  FROM @ST_CACHING_STAGE/data/user_events.csv
  FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 EMPTY_FIELD_AS_NULL = TRUE);

-- 2. Upload each app's code and dependencies.
PUT file://before/streamlit_app.py @ST_CACHING_STAGE/before AUTO_COMPRESS = FALSE OVERWRITE = TRUE;
PUT file://before/pyproject.toml   @ST_CACHING_STAGE/before AUTO_COMPRESS = FALSE OVERWRITE = TRUE;
PUT file://after/streamlit_app.py  @ST_CACHING_STAGE/after  AUTO_COMPRESS = FALSE OVERWRITE = TRUE;
PUT file://after/pyproject.toml    @ST_CACHING_STAGE/after  AUTO_COMPRESS = FALSE OVERWRITE = TRUE;

-- 3. Create both apps on the container runtime.
CREATE OR REPLACE STREAMLIT USER_ACTIVITY_BEFORE
  FROM '@ST_CACHING_STAGE/before'
  MAIN_FILE = 'streamlit_app.py'
  RUNTIME_NAME = 'SYSTEM$ST_CONTAINER_RUNTIME_PY3_11'
  COMPUTE_POOL = MY_COMPUTE_POOL
  QUERY_WAREHOUSE = MY_WAREHOUSE
  EXTERNAL_ACCESS_INTEGRATIONS = (MY_PYPI_ACCESS_INTEGRATION);

CREATE OR REPLACE STREAMLIT USER_ACTIVITY_AFTER
  FROM '@ST_CACHING_STAGE/after'
  MAIN_FILE = 'streamlit_app.py'
  RUNTIME_NAME = 'SYSTEM$ST_CONTAINER_RUNTIME_PY3_11'
  COMPUTE_POOL = MY_COMPUTE_POOL
  QUERY_WAREHOUSE = MY_WAREHOUSE
  EXTERNAL_ACCESS_INTEGRATIONS = (MY_PYPI_ACCESS_INTEGRATION);

-- 4. Check the data. The after app's Events metric should show this count.
SELECT COUNT(*) AS AMER_WEB_EVENTS
FROM USER_EVENTS_DEMO
WHERE REGION = 'AMER' AND CHANNEL = 'web';

-- Clean up when you're done:
-- DROP STREAMLIT IF EXISTS USER_ACTIVITY_BEFORE;
-- DROP STREAMLIT IF EXISTS USER_ACTIVITY_AFTER;
-- DROP STAGE IF EXISTS ST_CACHING_STAGE;
-- DROP TABLE IF EXISTS USER_EVENTS_DEMO;
