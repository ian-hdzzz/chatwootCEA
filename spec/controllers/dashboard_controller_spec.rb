require 'rails_helper'

describe '/app/login', type: :request do
  context 'without DEFAULT_LOCALE' do
    it 'renders the dashboard' do
      get '/app/login'
      expect(response).to have_http_status(:success)
    end
  end

  context 'with DEFAULT_LOCALE' do
    it 'renders the dashboard' do
      with_modified_env DEFAULT_LOCALE: 'pt_BR' do
        get '/app/login'
        expect(response).to have_http_status(:success)
        expect(response.body).to include "selectedLocale: 'pt_BR'"
      end
    end
  end

  context 'with non-HTML format' do
    it 'returns not acceptable for JSON with error message' do
      get '/app/login', headers: { 'Accept' => 'application/json' }
      expect(response).to have_http_status(:not_acceptable)
      expect(response.parsed_body).to eq({ 'error' => 'Please use API routes instead of dashboard routes for JSON requests' })
    end
  end

  # Routes are loaded once on app start
  # hence Rails.application.reload_routes! is used in this spec
  # ref : https://stackoverflow.com/a/63584877/939299
  context 'with CW_API_ONLY_SERVER true' do
    it 'returns 404' do
      with_modified_env CW_API_ONLY_SERVER: 'true' do
        Rails.application.reload_routes!
        get '/app/login'
        expect(response).to have_http_status(:not_found)
      end
      Rails.application.reload_routes!
    end
  end
  context 'with DASHBOARD_ALLOWED_ORIGINS' do
    it 'allows iframe embedding from allowed origins' do
      with_modified_env DASHBOARD_ALLOWED_ORIGINS: 'https://example.com' do
        get '/app/login'
        expect(response.headers['X-Frame-Options']).to be_nil
        expect(response.headers['Content-Security-Policy']).to include "frame-ancestors https://example.com"
      end
    end

    it 'does not allow iframe embedding if var is missing' do
      get '/app/login'
      # X-Frame-Options should be present (SAMEORIGIN usually default in Rails)
      expect(response.headers['X-Frame-Options']).to be_present
      expect(response.headers['Content-Security-Policy']).not_to include "frame-ancestors"
    end
  end
end
