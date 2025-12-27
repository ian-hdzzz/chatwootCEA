# Be sure to restart your server when you modify this file.

# For iframe embedding, we need SameSite=None. However, SameSite=None requires Secure=true.
# Secure=true only works over HTTPS, so in development (HTTP), we conditionally disable it.
if Rails.env.production?
  Rails.application.config.session_store :cookie_store, key: '_chatwoot_session', same_site: :none, secure: true
else
  # In development, use Lax so cookies work over HTTP. Iframe embedding won't work locally without HTTPS.
  Rails.application.config.session_store :cookie_store, key: '_chatwoot_session', same_site: :lax
end
