[![Status](https://img.shields.io/badge/status-active-success.svg?style=flat-square&logo=ruby)]()
[![GitHub issues](https://img.shields.io/github/issues/vijethph/WeatherForge?style=flat-square)](https://github.com/vijethph/WeatherForge/issues)
[![Contributors](https://img.shields.io/github/contributors/vijethph/WeatherForge?style=flat-square)](https://github.com/vijethph/WeatherForge/graphs/contributors)
[![GitHub forks](https://img.shields.io/github/forks/vijethph/WeatherForge?color=blue&style=flat-square)](https://github.com/vijethph/WeatherForge/network)
[![GitHub stars](https://img.shields.io/github/stars/vijethph/WeatherForge?color=yellow&style=flat-square)](https://github.com/vijethph/WeatherForge/stargazers)
[![GitHub license](https://img.shields.io/github/license/vijethph/WeatherForge?style=flat-square)](https://github.com/vijethph/WeatherForge/blob/master/LICENSE)
[![forthebadge](https://forthebadge.com/images/badges/made-with-ruby.svg)](https://forthebadge.com)
[![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy?repo=https://github.com/vijethph/WeatherForge)

<br/>

<div align="center">
  <a href="https://github.com/vijethph/WeatherForge">
    <img src="public/icon.png" alt="Logo" width="80" height="80">
  </a>

  <h3 align="center">WeatherForge</h3>

  <p align="center">
    A real-time weather dashboard
    <br />
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
    <li><a href="#deployment">Deployment</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>

<!-- ABOUT THE PROJECT -->

## About The Project

WeatherForge is a Rails 8.1+ real-time weather dashboard that integrates 7 Open Meteo APIs to provide comprehensive weather monitoring with live updates using Hotwire.

**Key Features:**

- Real-time weather data with automatic 5-minute updates
- Interactive charts for temperature, humidity, and wind speed trends
- Hourly forecasts and 10-day historical data
- Marine weather, air quality, and flood risk monitoring
- Location search with geocoding
- Background job processing with Sidekiq
- Swagger/OpenAPI documentation at `/api-docs`

|                                Weather Dashboard                                 |                                 Weather Trends                                 |
| :------------------------------------------------------------------------------: | :----------------------------------------------------------------------------: |
| <img src="screenshots/weatherforge1.png" alt="Weather Dashboard" height="400" /> | <img src="screenshots/weatherforge2.png" alt="Weather Trends" height="400"  /> |

|                                Weather Forecasts                                 |                                 Environmental Data                                 |
| :------------------------------------------------------------------------------: | :--------------------------------------------------------------------------------: |
| <img src="screenshots/weatherforge3.png" alt="Weather Forecasts" height="500" /> | <img src="screenshots/weatherforge4.png" alt="Environmental Data" height="500"  /> |

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Built With

- [![Rails][Rails.js]][Rails-url]
- [![Ruby][Ruby.js]][Ruby-url]
- [![PostgreSQL][PostgreSQL.js]][PostgreSQL-url]
- [![Redis][Redis.js]][Redis-url]
- [![Bootstrap][Bootstrap.com]][Bootstrap-url]

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

## Getting Started

### Prerequisites

- Ruby 3.4+
  ```sh
  ruby --version
  ```
- Node.js 22+
  ```sh
  node --version
  ```
- Docker (for Redis)
  ```sh
  docker --version
  ```

### Installation

1. Clone the repo

   ```sh
   git clone https://github.com/vijethph/WeatherForge.git
   cd WeatherForge
   ```

2. Install dependencies

   ```sh
   bundle install
   npm install
   ```

3. Setup database

   ```sh
   rails db:setup
   ```

4. Start Redis

   ```sh
   docker compose up -d redis
   ```

5. Start the server (starts Rails + JS build watcher)

   ```sh
   bin/dev
   ```

6. Start Sidekiq (in separate terminal)

   ```sh
   bundle exec sidekiq
   ```

7. Visit `http://localhost:3000`

**Additional URLs:**

- API Docs: `http://localhost:3000/api-docs`
- Sidekiq Dashboard: `http://localhost:3000/sidekiq`

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- USAGE -->

## Usage

### Dashboard Pages

- `/` - Main dashboard with current weather for all locations
- `/dashboards/trends` - 24-hour temperature, humidity, wind charts
- `/dashboards/forecasts` - Hourly forecasts and historical data
- `/dashboards/environment` - Marine weather, air quality, flood risk

### Managing Locations

**Add Location:**

1. Navigate to Locations page
2. Search for a city or enter coordinates
3. Submit to add location

**Sync Weather:**

- Automatic: Every 5 minutes via Sidekiq
- Manual: Click "Sync All Weather" button

### API Endpoints

```
GET  /                              # Main dashboard
GET  /dashboards/trends             # Trends page
GET  /dashboards/forecasts          # Forecasts page
GET  /dashboards/environment        # Environment page
POST /dashboards/sync_weather       # Manual sync

GET  /locations                     # List locations
GET  /locations/search?query=city   # Search locations
POST /locations                     # Create location
DELETE /locations/:id               # Delete location
```

Interactive API documentation available at `/api-docs`.

### Testing

```bash
# Run tests
bundle exec rspec

# Run with coverage
COVERAGE=true bundle exec rspec

# Code quality
bundle exec rubocop
bundle exec brakeman
bundle exec bundler-audit
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- DEPLOYMENT -->

## Deployment

### Render (Recommended)

The app includes `render.yaml` for one-click deployment with PostgreSQL and Redis.

1. Push code to GitHub
2. Connect repository to Render
3. Set `RAILS_MASTER_KEY` environment variable
4. Deploy automatically on push to main

### Docker

```bash
# Build image
docker build -t weatherforge .

# Run with docker-compose
docker compose up
```

### Environment Variables

Required for production:

```
RAILS_MASTER_KEY=your_master_key
DATABASE_URL=postgresql://user:pass@host:5432/dbname
REDIS_URL=redis://host:6379/0
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- CONTRIBUTING -->

## Contributing

Contributions are welcome!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
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

## Acknowledgements

- [Open Meteo](https://open-meteo.com/) - Free weather API
- [Chartkick](https://chartkick.com/) - JavaScript charts for Ruby
- [Bootstrap](https://getbootstrap.com/) - CSS framework
- [Sidekiq](https://sidekiq.org/) - Background processing

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- MARKDOWN LINKS & IMAGES -->

[Rails.js]: https://img.shields.io/badge/Rails-8.1-CC0000?style=for-the-badge&logo=ruby-on-rails&logoColor=white
[Rails-url]: https://rubyonrails.org/
[Ruby.js]: https://img.shields.io/badge/Ruby-3.4-CC342D?style=for-the-badge&logo=ruby&logoColor=white
[Ruby-url]: https://www.ruby-lang.org/
[PostgreSQL.js]: https://img.shields.io/badge/PostgreSQL-17-316192?style=for-the-badge&logo=postgresql&logoColor=white
[PostgreSQL-url]: https://www.postgresql.org/
[Redis.js]: https://img.shields.io/badge/Redis-8.2-DC382D?style=for-the-badge&logo=redis&logoColor=white
[Redis-url]: https://redis.io/
[Bootstrap.com]: https://img.shields.io/badge/Bootstrap-5.3-563D7C?style=for-the-badge&logo=bootstrap&logoColor=white
[Bootstrap-url]: https://getbootstrap.com
