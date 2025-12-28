# Cookie options for iframe embedding support
# In production, we need SameSite=None and Secure=true for cross-origin iframe cookies
def warden_cookie_options
  if Rails.env.production?
    { same_site: :none, secure: true }
  else
    { same_site: :lax }
  end
end

Warden::Manager.after_set_user do |user, auth, opts|
  scope = opts[:scope]
  auth.cookies.signed["#{scope}.id"] = { value: user.id, **warden_cookie_options }
  auth.cookies.signed["#{scope}.expires_at"] = { value: 30.minutes.from_now, **warden_cookie_options }
end

Warden::Manager.before_logout do |_user, auth, opts|
  scope = opts[:scope]
  auth.cookies.delete("#{scope}.id", **warden_cookie_options)
  auth.cookies.delete("#{scope}.expires_at", **warden_cookie_options)
end
