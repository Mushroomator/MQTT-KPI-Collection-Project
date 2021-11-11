/*
    Create "read-only" user for Grafana
*/
-- Create user "grafanareader"
CREATE USER grafanareader WITH PASSWORD 'pw';
-- Grant user "grafanareader" to connect to database "kpis"
GRANT CONNECT ON DATABASE kpis TO grafanareader;
-- Grant "grafanareader" access to schema "kpis"
\c kpis
GRANT USAGE ON SCHEMA public TO grafanareader;
-- Only allow "grafanareader" to read from tables
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO grafanareader;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO grafanareader;

/*
    Create "insert-only" user for Database-Connector
*/
-- Create user "db-con"
CREATE USER dbcon WITH PASSWORD 'pw';
-- Grant user "grafanareader" to connect to database "kpis"
GRANT CONNECT ON DATABASE kpis TO dbcon;
\c kpis
-- Grant "db-con" access to schema "kpis"
GRANT USAGE ON SCHEMA public TO dbcon;
-- Only allow "db-con" to insert into "kpis" and "images"
GRANT UPDATE ON ALL SEQUENCES IN SCHEMA public TO dbcon;
GRANT INSERT ON TABLE public.kpis, public.images TO dbcon;