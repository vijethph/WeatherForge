if Rails.env.production?
  Rails.application.configure do
    config.lograge.enabled = true
    config.lograge.formatter = Lograge::Formatters::Json.new
    config.lograge.logger = Logger.new(Rails.root.join("log/app.log"))

    config.log_level = :info
  end
end
