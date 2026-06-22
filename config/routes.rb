Rails.application.routes.draw do
  devise_for :users, controllers: {
    omniauth_callbacks: "users/omniauth_callbacks",
    registrations: "users/registrations"
  }

  # 初回セットアップ
  resource :setup, only: %i[new create], controller: "setup"

  # トップページ（アップロード一覧）
  root "image_groups#index"

  # 画像グループ
  resources :image_groups, only: %i[index show new create destroy] do
    member do
      get :download
    end
  end

  # 画像（グループ内）
  resources :images, only: %i[show destroy] do
    member do
      post :retry
      get :download
    end
  end

  # 管理者画面
  namespace :admin do
    resource :statistics, only: [ :show ]
    resources :identity_providers do
      collection do
        post :restart_app
        post :parse_saml_metadata
        patch :update_saml_sp_entity_id
      end
    end
    resource :settings, only: [ :show ] do
      patch :update_auth, on: :member
      patch :update_passkey, on: :member
      patch :update_ocr, on: :member
      patch :update_quota, on: :member
      patch :update_retention, on: :member
      patch :update_pdf, on: :member
      patch :update_notification, on: :member
      patch :update_smtp, on: :member
      patch :update_timezone, on: :member
      patch :update_affil_priority, on: :member
      post :send_test_email, on: :member
    end
    resources :users, only: %i[index] do
      member do
        patch :toggle_admin
        patch :invalidate_sessions
        patch :update_priority
      end
    end
    resources :images, only: %i[index destroy]
    resources :ocr_prompt_patterns, except: %i[show] do
      member do
        patch :set_default
      end
    end
  end

  # パスキー
  namespace :passkeys do
    resources :registrations, only: %i[new create]
    resources :sessions, only: %i[new create]
    resources :credentials, only: %i[index update destroy]
  end

  # SAML SP メタデータ
  get "saml/metadata" => "saml_metadata#show", as: :saml_metadata

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
