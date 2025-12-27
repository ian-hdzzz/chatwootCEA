# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy

Rails.application.config.content_security_policy do |policy|
  policy.default_src :self, :https
  policy.font_src    :self, :https, :data
  policy.img_src     :self, :https, :data, :blob
  policy.object_src  :none
  policy.script_src  :self, :https
  # Allow @vite/client to hot reload javascript changes in development
  policy.script_src *policy.script_src, :unsafe_eval, "http://#{ ViteRuby.config.host_with_port }" if Rails.env.development?
  # You may need to enable this in production as well depending on your setup.
  policy.script_src *policy.script_src, :blob if Rails.env.test?
  policy.style_src   :self, :https
  # Allow @vite/client to hot reload style changes in development
  policy.style_src *policy.style_src, :unsafe_inline if Rails.env.development?
  # Allow @vite/client to hot reload changes in development
  policy.connect_src *policy.connect_src, "ws://#{ ViteRuby.config.host_with_port }" if Rails.env.development?

  # Configuración de frame-ancestors para permitir embedding
  # Puedes configurar dominios específicos mediante variable de entorno
  allowed_frame_ancestors = ENV.fetch('ALLOWED_FRAME_ANCESTORS', '').split(',').map(&:strip)
  
  if Rails.env.development? || allowed_frame_ancestors.include?('*')
    # En desarrollo o si se especifica *, permitir todos los dominios
    # NOTA: Esto es inseguro para producción, usa solo para testing
    policy.frame_ancestors :self, :https, :http, 'http://localhost:*', 'http://127.0.0.1:*'
  elsif allowed_frame_ancestors.any?
    # Usar dominios específicos de la variable de entorno
    policy.frame_ancestors :self, *allowed_frame_ancestors
  else
    # Por defecto, solo permitir mismo origen
    policy.frame_ancestors :self
  end

  # Specify URI for violation reports
  # policy.report_uri "/csp-violation-report-endpoint"
end

# If you are using UJS then enable automatic nonce generation
# Rails.application.config.content_security_policy_nonce_generator = -> request { SecureRandom.base64(16) }

# Set the nonce only to specific directives
# Rails.application.config.content_security_policy_nonce_directives = %w(script-src)

# Report CSP violations to a specified URI
# For further information see the following documentation:
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy-Report-Only
# Rails.application.config.content_security_policy_report_only = true
