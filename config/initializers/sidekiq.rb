# Sidekiq 8.1 Configuration
# Connects to Redis 8.2-alpine running in Docker container
# Default: redis://localhost:6379/1 (Docker port mapping)
# Production: Set REDIS_URL environment variable

# Skip Sidekiq configuration during asset precompilation
# When SKIP_REDIS is set, Rails is just precompiling assets and doesn't need Redis
unless ENV['SKIP_REDIS'] == 'true'
  Sidekiq.configure_server do |config|
    config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/1") }
  end

  Sidekiq.configure_client do |config|
    config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/1") }
  end
end
