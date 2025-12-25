# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Dashboards API', type: :request do
  path '/dashboards' do
    get 'Retrieve main dashboard' do
      tags 'Dashboards'
      produces 'text/html'
      description 'Returns the main weather dashboard with all location weather cards'

      response '200', 'successful' do
        schema type: :string, format: :html
        run_test! do |response|
          expect(response).to have_http_status(:ok)
          expect(response.content_type).to match(%r{text/html})
        end
      end
    end
  end

  path '/dashboards/trends' do
    get 'Retrieve weather trends' do
      tags 'Dashboards'
      produces 'text/html'
      description 'Returns 24-hour weather trends including temperature, humidity, and wind speed charts'

      response '200', 'successful' do
        schema type: :string, format: :html
        run_test! do |response|
          expect(response).to have_http_status(:ok)
          expect(response.content_type).to match(%r{text/html})
        end
      end
    end
  end

  path '/dashboards/forecasts' do
    get 'Retrieve weather forecasts' do
      tags 'Dashboards'
      produces 'text/html'
      description 'Returns weather forecast data including 24-hour forecast and 10-day historical weather'

      response '200', 'successful' do
        schema type: :string, format: :html
        run_test! do |response|
          expect(response).to have_http_status(:ok)
          expect(response.content_type).to match(%r{text/html})
        end
      end
    end
  end

  path '/dashboards/environment' do
    get 'Retrieve environmental data' do
      tags 'Dashboards'
      produces 'text/html'
      description 'Returns environmental data including marine weather, air quality, and flood risk information'

      response '200', 'successful' do
        schema type: :string, format: :html
        run_test! do |response|
          expect(response).to have_http_status(:ok)
          expect(response.content_type).to match(%r{text/html})
        end
      end
    end
  end

  path '/dashboards/sync_weather' do
    post 'Trigger weather data sync' do
      tags 'Dashboards'
      consumes 'application/x-www-form-urlencoded'
      produces 'text/html'
      description 'Manually triggers a weather data synchronization for all locations via Sidekiq background job'

      response '302', 'redirect after sync' do
        schema type: :string
        run_test! do |response|
          expect(response).to have_http_status(:found)
          expect(response).to redirect_to(dashboards_path)
        end
      end
    end
  end
end
