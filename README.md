<div align="center">
  <h1>WeatherForge</h1>

  <p>
    <strong>Advanced Real-Time Weather Dashboard with Multi-API Integration</strong>
  </p>

  <p>
    A Rails 8.1+ application that integrates multiple Open Meteo APIs to provide comprehensive weather data, forecasts, marine conditions, air quality, and flood risk information with live updates using Hotwire.
  </p>

  <p>
    <a href="https://github.com/vijethph/WeatherForge/issues">Report Bug</a>
    ·
    <a href="https://github.com/vijethph/WeatherForge/issues">Request Feature</a>
  </p>
</div>

<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
      <ul>
        <li><a href="#key-features">Key Features</a></li>
        <li><a href="#built-with">Built With</a></li>
      </ul>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#api-documentation">API Documentation</a></li>
    <li><a href="#architecture">Architecture</a></li>
    <li><a href="#testing">Testing</a></li>
    <li><a href="#deployment">Deployment</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>

<!-- ABOUT THE PROJECT -->

## About The Project

WeatherForge is an advanced real-time weather dashboard that demonstrates modern Rails 8.1+ development practices with comprehensive API integration, real-time updates, and background job processing. The application fetches data from 7 different Open Meteo API endpoints to provide a complete weather monitoring solution.

### Key Features

- **Real-Time Weather Data** - Current conditions for multiple locations with automatic 5-minute updates
- **Interactive Visualizations** - Beautiful charts showing 24-hour trends for temperature, humidity, and wind speed
- **Comprehensive Forecasts** - Hourly forecasts for next 24 hours and 10-day historical data
- **Marine Weather Integration** - Wave height, period, and water temperature data
- **Air Quality Monitoring** - PM2.5, PM10, O3, NO2, SO2 metrics with AQI level calculations
- **Flood Risk Assessment** - Probability and severity information for locations
- **Live Dashboard Updates** - Real-time updates via Turbo Streams without page refresh
- **Intelligent Location Search** - Geocoding-powered location discovery with autocomplete
- **Background Processing** - Automated weather syncing every 5 minutes using Sidekiq
- **API Documentation** - Comprehensive Swagger/OpenAPI documentation for all endpoints

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Built With

- [![Rails][Rails.js]][Rails-url]
- [![Ruby][Ruby.js]][Ruby-url]
- [![PostgreSQL][PostgreSQL.js]][PostgreSQL-url]
- [![Redis][Redis.js]][Redis-url]
- [![Bootstrap][Bootstrap.com]][Bootstrap-url]
- [![Hotwire][Hotwire.js]][Hotwire-url]

**Core Technologies:**

- **Rails 8.1+** - Modern web framework with Hotwire integration
- **Ruby 3.4+** - Latest Ruby with performance improvements
- **PostgreSQL 15+** - Production database (SQLite3 for development)
- **Redis 8.2** - Job queue and caching layer
- **Hotwire (Turbo + Stimulus)** - Real-time updates and reactive UI
- **Sidekiq 8.1** - Background job processing with scheduler
- **Bootstrap 5.3** - Responsive UI framework
- **Chartkick + Chart.js** - Interactive data visualizations
- **HTTParty** - HTTP client for API integrations
- **RSwag** - Swagger/OpenAPI 3.0 documentation

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

## Getting Started

To get a local copy up and running, follow these simple steps.

### Prerequisites

Before you begin, ensure you have the following installed:

- **Ruby 3.4+**

  ```sh
  ruby --version
  # ruby 3.4.5 (or higher)
  ```

- **Node.js 22+** and npm

  ```sh
  node --version
  # v22.0.0 (or higher)
  npm --version
  ```

- **Docker** (for Redis)

  ```sh
  docker --version
  # Docker version 24.0.0 (or higher)
  ```

- **PostgreSQL 15+** (for production deployment)
  ```sh
  psql --version
  # psql (PostgreSQL) 15.0 (or higher)
  ```

### Installation

1. **Clone the repository**

   ```sh
   git clone https://github.com/vijethph/WeatherForge.git
   cd WeatherForge
   ```

2. **Install Ruby dependencies**

   ```sh
   bundle install
   ```

3. **Install JavaScript dependencies**

   ```sh
   npm install
   ```

4. **Setup the database**

   ```sh
   rails db:setup
   ```

   This creates the database, runs migrations, and seeds default locations (San Francisco, London, Tokyo).

5. **Start Redis container**

   ```sh
   docker compose up -d redis
   ```

   Redis is required for Sidekiq job processing.

6. **Start the development server**

   ```sh
   bin/dev
   ```

   This starts both the Rails server and JavaScript build watcher using Foreman.

7. **Start Sidekiq worker** (in a separate terminal)

   ```sh
   bundle exec sidekiq
   ```

   Sidekiq processes background jobs for weather data syncing.

8. **Visit the application**

   Open your browser and navigate to `http://localhost:3000`

   **Additional URLs:**

   - API Documentation: `http://localhost:3000/api-docs`
   - Sidekiq Dashboard: `http://localhost:3000/sidekiq`

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- USAGE -->

## Usage

### Dashboard Views

WeatherForge provides four main dashboard views:

1. **Main Dashboard** (`/`) - Overview with current weather for all locations
2. **Trends** (`/dashboards/trends`) - 24-hour temperature, humidity, and wind speed charts
3. **Forecasts** (`/dashboards/forecasts`) - Hourly forecasts and historical data
4. **Environment** (`/dashboards/environment`) - Marine weather, air quality, and flood risk

### Managing Locations

**Add a Location:**

1. Navigate to the Locations page
2. Use the search feature to find a city
3. Click on a search result or manually enter coordinates
4. Submit the form to add the location

**Remove a Location:**

1. Find the location card on the dashboard
2. Click the "Remove" button
3. Confirm the deletion

### Syncing Weather Data

Weather data automatically syncs every 5 minutes via Sidekiq. To manually trigger a sync:

1. Click the "Sync All Weather" button on the dashboard
2. Wait for the background job to complete
3. Dashboard updates automatically via Turbo Streams

### API Endpoints

The application provides RESTful API endpoints:

```
GET  /                              # Main dashboard
GET  /dashboards/trends             # Trends page
GET  /dashboards/forecasts          # Forecasts page
GET  /dashboards/environment        # Environment page
POST /dashboards/sync_weather       # Manual weather sync

GET  /locations                     # List all locations
GET  /locations/search?query=city   # Search locations
POST /locations                     # Create location
DELETE /locations/:id               # Delete location
```

For detailed API documentation, visit `/api-docs` in your browser.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- API DOCUMENTATION -->

## API Documentation

WeatherForge includes comprehensive API documentation powered by Swagger/OpenAPI 3.0.

### Accessing the Documentation

Visit `http://localhost:3000/api-docs` to explore the interactive API documentation.

### Generating Documentation

After updating API specs, regenerate the documentation:

```bash
RAILS_ENV=test rails rswag:specs:swaggerize
```

### Documentation Files

- `spec/swagger_helper.rb` - OpenAPI configuration and schemas
- `spec/requests/dashboards_spec.rb` - Dashboard endpoints documentation
- `spec/requests/locations_spec.rb` - Location endpoints documentation
- `swagger/v1/swagger.yaml` - Generated OpenAPI specification

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- ARCHITECTURE -->

## Architecture

### Core Data Flow

```
Open Meteo APIs (7 endpoints) → WeatherService → SyncWeatherJob (every 5 min)
                                                        ↓
                                Multiple Model Creation (WeatherMetric, HourlyForecast,
                                HistoricalWeather, MarineWeather, AirQuality, FloodRisk)
                                                        ↓
                                Turbo::StreamsChannel.broadcast_update_to
                                                        ↓
                                Live dashboard updates (no page refresh)
```

### Key Components

**Models (7 total):**

- `Location` - Stores city coordinates, timezone, elevation
- `WeatherMetric` - Current weather data
- `HourlyForecast` - 24-hour forecast data
- `HistoricalWeather` - 10-day historical data
- `MarineWeather` - Marine conditions
- `AirQuality` - Air quality metrics
- `FloodRisk` - Flood risk data

**Services:**

- `WeatherService` - HTTParty wrapper for all Open Meteo APIs (7 endpoints)

**Background Jobs:**

- `SyncWeatherJob` - Runs every 5 minutes via Sidekiq scheduler

**Controllers:**

- `DashboardsController` - Main dashboard and chart views
- `LocationsController` - Location management and search

### Open Meteo API Integration

The application integrates 7 different Open Meteo APIs:

1. **Weather Forecast API** - Current weather and hourly forecasts
2. **Historical Weather API** - Past weather data (10 days)
3. **Marine Weather API** - Wave height, period, water temperature
4. **Air Quality API** - PM2.5, PM10, O3, NO2, SO2 levels
5. **Flood API** - Flood probability and severity
6. **Geocoding API** - Location search and coordinates
7. **Elevation API** - Altitude data for locations

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- TESTING -->

## Testing

### Running Tests

```bash
# Run all tests
bundle exec rspec

# Run with coverage report
COVERAGE=true bundle exec rspec

# Run specific test file
bundle exec rspec spec/models/location_spec.rb
```

### Code Quality Tools

```bash
# Ruby style checking
bundle exec rubocop

# Auto-fix style violations
bundle exec rubocop -a

# Security vulnerability scanning
bundle exec brakeman

# Check for vulnerable gem versions
bundle exec bundler-audit
```

### Test Suite

- **RSpec** - Testing framework
- **FactoryBot** - Test data factories
- **Faker** - Realistic fake data
- **Shoulda Matchers** - Model testing helpers
- **SimpleCov** - Code coverage reporting

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- DEPLOYMENT -->

## Deployment

### Render Deployment

WeatherForge is configured for deployment on Render with PostgreSQL and Redis.

**Quick Deploy:**

[![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy)

**Manual Deployment:**

See [Render Deployment Guide](docs/RENDER_DEPLOYMENT_GUIDE.md) for detailed instructions.

### Docker Deployment

```bash
# Build the image
docker build -t weatherforge .

# Run with Docker Compose
docker compose up
```

See [Docker Deployment Guide](docs/DOCKER_DEPLOYMENT_GUIDE.md) for more details.

### Environment Variables

Required environment variables for production:

```
RAILS_MASTER_KEY=your_master_key
DATABASE_URL=postgresql://user:pass@host:5432/dbname
REDIS_URL=redis://host:6379/0
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- CONTRIBUTING -->

## Contributing

Contributions make the open source community an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/amazing-feature`)
3. Commit your Changes using [Conventional Commits](https://www.conventionalcommits.org)
   ```sh
   git commit -m 'feat: add amazing feature'
   ```
4. Push to the Branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- LICENSE -->

## License

Distributed under the Apache License 2.0. See `LICENSE` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- CONTACT -->

## Contact

Vijeth P H - [@vijethph](https://github.com/vijethph)

Project Link: [https://github.com/vijethph/WeatherForge](https://github.com/vijethph/WeatherForge)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- ACKNOWLEDGMENTS -->

## Acknowledgments

- [Open Meteo](https://open-meteo.com/) - Free weather API with no authentication required
- [Chartkick](https://chartkick.com/) - Beautiful JavaScript charts for Ruby
- [Chart.js](https://www.chartjs.org/) - Simple yet flexible JavaScript charting
- [Bootstrap](https://getbootstrap.com/) - Popular CSS framework for responsive design
- [Hotwire](https://hotwired.dev/) - HTML-over-the-wire approach for modern web apps
- [Sidekiq](https://sidekiq.org/) - Simple, efficient background processing for Ruby
- [RSwag](https://github.com/rswag/rswag) - OpenAPI/Swagger documentation for Rails
- [Best-README-Template](https://github.com/othneildrew/Best-README-Template) - README template
- [Choose an Open Source License](https://choosealicense.com)
- [GitHub Emoji Cheat Sheet](https://github.com/ikatyang/emoji-cheat-sheet)
- [Img Shields](https://shields.io)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- MARKDOWN LINKS & IMAGES -->

[Rails.js]: https://img.shields.io/badge/Rails-8.1-CC0000?style=for-the-badge&logo=ruby-on-rails&logoColor=white
[Rails-url]: https://rubyonrails.org/
[Ruby.js]: https://img.shields.io/badge/Ruby-3.4-CC342D?style=for-the-badge&logo=ruby&logoColor=white
[Ruby-url]: https://www.ruby-lang.org/
[PostgreSQL.js]: https://img.shields.io/badge/PostgreSQL-15-316192?style=for-the-badge&logo=postgresql&logoColor=white
[PostgreSQL-url]: https://www.postgresql.org/
[Redis.js]: https://img.shields.io/badge/Redis-8.2-DC382D?style=for-the-badge&logo=redis&logoColor=white
[Redis-url]: https://redis.io/
[Bootstrap.com]: https://img.shields.io/badge/Bootstrap-5.3-563D7C?style=for-the-badge&logo=bootstrap&logoColor=white
[Bootstrap-url]: https://getbootstrap.com
[Hotwire.js]: https://img.shields.io/badge/Hotwire-Turbo-orange?style=for-the-badge
[Hotwire-url]: https://hotwired.dev/
