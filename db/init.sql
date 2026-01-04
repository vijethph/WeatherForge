-- PostgreSQL initialization script for WeatherForge
-- Enables PostGIS extension and creates necessary databases
-- Note: This script runs automatically when PostgreSQL container starts for the first time

-- Enable PostGIS extension for spatial features in the default database (weatherforge_development)
CREATE EXTENSION IF NOT EXISTS postgis;

-- Enable PostGIS topology support
CREATE EXTENSION IF NOT EXISTS postgis_topology;

-- Optional: Enable PostGIS raster support (uncomment if needed)
-- CREATE EXTENSION IF NOT EXISTS postgis_raster;

-- Create test database for running tests
CREATE DATABASE weatherforge_test;

-- Connect to test database and enable PostGIS extensions
\c weatherforge_test

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;

-- Return to development database
\c weatherforge_development

-- Verify PostGIS installation and show version
SELECT 'PostGIS installed successfully. Version: ' || PostGIS_Version() AS status;
