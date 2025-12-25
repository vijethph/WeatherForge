# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.openapi_root = Rails.root.join('swagger').to_s

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under openapi_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a openapi_spec tag to the
  # the root example_group in your specs, e.g. describe '...', openapi_spec: 'v2/swagger.json'
  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'WeatherForge API',
        version: 'v1',
        description: 'Real-time weather dashboard API with support for current weather, forecasts, historical data, marine conditions, air quality, and flood risk information. Powered by Open Meteo APIs.',
        contact: {
          name: 'WeatherForge',
          url: 'https://github.com/vijethph/WeatherForge'
        },
        license: {
          name: 'MIT',
          url: 'https://opensource.org/licenses/MIT'
        }
      },
      paths: {},
      servers: [
        {
          url: 'http://localhost:3000',
          description: 'Development server'
        },
        {
          url: 'https://{defaultHost}',
          description: 'Production server',
          variables: {
            defaultHost: {
              default: 'weatherforge.onrender.com'
            }
          }
        }
      ],
      components: {
        schemas: {
          Location: {
            type: 'object',
            properties: {
              id: { type: 'integer', example: 1 },
              name: { type: 'string', example: 'San Francisco' },
              latitude: { type: 'number', format: 'float', example: 37.7749 },
              longitude: { type: 'number', format: 'float', example: -122.4194 },
              timezone: { type: 'string', example: 'America/Los_Angeles' },
              country: { type: 'string', example: 'US' },
              description: { type: 'string', example: 'Tech hub', nullable: true },
              elevation: { type: 'number', format: 'float', example: 52.0, nullable: true },
              created_at: { type: 'string', format: 'date-time' },
              updated_at: { type: 'string', format: 'date-time' }
            },
            required: [ 'name', 'latitude', 'longitude' ]
          },
          WeatherMetric: {
            type: 'object',
            properties: {
              id: { type: 'integer', example: 1 },
              location_id: { type: 'integer', example: 1 },
              temperature: { type: 'number', format: 'float', example: 20.5 },
              feels_like: { type: 'number', format: 'float', example: 19.8 },
              humidity: { type: 'integer', example: 65 },
              wind_speed: { type: 'number', format: 'float', example: 12.5 },
              wind_direction: { type: 'integer', example: 180 },
              wind_gust: { type: 'number', format: 'float', example: 20.0 },
              precipitation: { type: 'number', format: 'float', example: 0.0 },
              weather_code: { type: 'integer', example: 1 },
              cloud_cover: { type: 'integer', example: 25 },
              pressure: { type: 'number', format: 'float', example: 1013.25 },
              visibility: { type: 'number', format: 'float', example: 10000.0 },
              recorded_at: { type: 'string', format: 'date-time' }
            }
          },
          Error: {
            type: 'object',
            properties: {
              error: { type: 'string', example: 'Resource not found' },
              message: { type: 'string', example: 'The requested resource could not be found' }
            }
          }
        }
      }
    }
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The openapi_specs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.openapi_format = :yaml
end
