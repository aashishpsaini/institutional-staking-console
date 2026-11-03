# frozen_string_literal: true

# The Vite dev server proxies /api, so CORS only matters when the UI is served
# from a different origin. Restrict to known origins rather than "*".
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*ENV.fetch("CORS_ORIGINS", "http://localhost:5173").split(","))
    resource "/api/*",
             headers: %w[ Content-Type Accept X-Api-Key Idempotency-Key ],
             methods: %i[ get post options ]
  end
end
