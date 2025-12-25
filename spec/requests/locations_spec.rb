# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Locations API', type: :request do
  let!(:existing_location) { create(:location) }

  path '/locations' do
    get 'List all locations' do
      tags 'Locations'
      produces 'text/html'
      description 'Returns a list of all weather locations with search and add location forms'

      response '200', 'successful' do
        schema type: :string, format: :html
        run_test! do |response|
          expect(response).to have_http_status(:ok)
          expect(response.content_type).to match(%r{text/html})
        end
      end
    end

    post 'Create a new location' do
      tags 'Locations'
      consumes 'application/x-www-form-urlencoded'
      produces 'text/html'
      description 'Creates a new weather location and triggers elevation fetch and weather sync'

      parameter name: 'location[name]', in: :formData, type: :string, description: 'Location name', example: 'New York'
      parameter name: 'location[latitude]', in: :formData, type: :number, format: :float, description: 'Latitude', example: 40.7128, required: true
      parameter name: 'location[longitude]', in: :formData, type: :number, format: :float, description: 'Longitude', example: -74.0060, required: true
      parameter name: 'location[timezone]', in: :formData, type: :string, description: 'Timezone', example: 'America/New_York'
      parameter name: 'location[country]', in: :formData, type: :string, description: 'Country code', example: 'US'
      parameter name: 'location[description]', in: :formData, type: :string, description: 'Description', example: 'The Big Apple', required: false

      response '302', 'location created successfully' do
        let(:'location[name]') { 'New York' }
        let(:'location[latitude]') { 40.7128 }
        let(:'location[longitude]') { -74.0060 }
        let(:'location[timezone]') { 'America/New_York' }
        let(:'location[country]') { 'US' }

        before do
          allow_any_instance_of(WeatherService).to receive(:fetch_elevation).and_return(10.0)
          allow(SyncWeatherJob).to receive(:perform_later)
        end

        run_test! do |response|
          expect(response).to have_http_status(:found)
          expect(response).to redirect_to(dashboards_path)
        end
      end

      response '422', 'invalid request' do
        let(:'location[name]') { '' }
        let(:'location[latitude]') { nil }
        let(:'location[longitude]') { nil }
        let(:'location[timezone]') { nil }
        let(:'location[country]') { nil }

        run_test! do |response|
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  path '/locations/search' do
    get 'Search for locations using geocoding' do
      tags 'Locations'
      produces 'application/json', 'text/html'
      description 'Search for locations using Open Meteo Geocoding API. Requires minimum 3 characters.'

      parameter name: :query, in: :query, type: :string, required: true, description: 'Search query (minimum 3 characters)', example: 'London'

      response '200', 'successful search' do
        schema type: :object,
               properties: {
                 results: {
                   type: :array,
                   items: {
                     type: :object,
                     properties: {
                       name: { type: :string, example: 'London' },
                       latitude: { type: :number, format: :float, example: 51.5074 },
                       longitude: { type: :number, format: :float, example: -0.1278 },
                       country: { type: :string, example: 'GB' },
                       timezone: { type: :string, example: 'Europe/London' }
                     }
                   }
                 }
               }

        let(:query) { 'London' }

        run_test! do |response|
          expect(response).to have_http_status(:ok)
        end
      end

      response '200', 'query too short' do
        let(:query) { 'Lo' }

        run_test! do |response|
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['results']).to be_empty
        end
      end
    end
  end

  path '/locations/{id}' do
    delete 'Delete a location' do
      tags 'Locations'
      produces 'text/html'
      description 'Deletes a weather location and all associated weather data'

      parameter name: :id, in: :path, type: :integer, required: true, description: 'Location ID', example: 1

      response '302', 'location deleted successfully' do
        let(:id) { create(:location).id }

        run_test! do |response|
          expect(response).to have_http_status(:found)
          expect(response).to redirect_to(dashboards_path)
        end
      end

      response '404', 'location not found' do
        let(:id) { 99999 }

        run_test!
      end
    end
  end
end
