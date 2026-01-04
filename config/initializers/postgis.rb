# frozen_string_literal: true

# Configure Rails to ignore PostGIS internal schemas when dumping schema
Rails.application.config.active_record.schema_format = :ruby
Rails.application.config.active_record.dump_schemas = :schema_search_path

# Exclude PostGIS internal schemas from schema dump
ActiveRecord::SchemaDumper.ignore_tables = %w[
  topology.layer
  topology.topology
  tiger.addr
  tiger.addrfeat
  tiger.bg
  tiger.county
  tiger.county_lookup
  tiger.countysub_lookup
  tiger.cousub
  tiger.direction_lookup
  tiger.edges
  tiger.faces
  tiger.featnames
  tiger.geocode_settings
  tiger.geocode_settings_default
  tiger.loader_lookuptables
  tiger.loader_platform
  tiger.loader_variables
  tiger.pagc_gaz
  tiger.pagc_lex
  tiger.pagc_rules
  tiger.place
  tiger.place_lookup
  tiger.secondary_unit_lookup
  tiger.state
  tiger.state_lookup
  tiger.street_type_lookup
  tiger.tabblock
  tiger.tabblock20
  tiger.tract
  tiger.zcta5
  tiger.zip_lookup
  tiger.zip_lookup_all
  tiger.zip_lookup_base
  tiger.zip_state
  tiger.zip_state_loc
]
