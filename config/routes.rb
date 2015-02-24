Tracker::Application.routes.draw do



  get "sync_merge/index"

  get "sync_merge/show"

  post "sync_merge/update"

  get "sync_service/index"

  post "sync_service/login"

	post "sync_service/sync"

  post "sync_service/download"

  post "sync_service/upload"

  
	get "sync_client/index"

  post "sync_client/login"

	post "sync_client/sync"

  post "sync_client/download"

  post "sync_client/upload"

  #resources :attachments


  resources :dvcs_configs


  #resources :version_control_branches


  get "sync_manager/login"

  get "sync_manager/sync"

  resources :user_rights

  resources :nodes do
		collection do
			get :setup
		end
	end

  resources :commits

  resources :issue_types

  resources :develement_types

  resources :users do
    collection do
      get :login
      get :logout
      post :authenticate
			get :show_owner_detail
			get :download_cert
			get :change_password
			post :update_password
    end
  end

  resources :projects do
		resources :packages
		resources :attachments
    resources :commits
    resources :issues do
      resources :commits
			resources :attachments
      member do
        post :update_status
      end
      collection do
        post :filter_status
				post :find_by_code
      end
    end
    resources :develements do
      resources :commits
			resources :attachments
      member do
        get :add_variances
        put :update_variances
        post :update_status
      end
      collection do
        post :filter_status
				get :filter_status
				post :find_by_code
				get :batch_process
				post :update_batch
				post :select_batch_update_field
				post :batch_update_filter
      end
    end 
    resources :schedules do
      member do
        post :update_status
      end
    end
    resources :variances do
      resources :version_controls
      resources :schedules
      member do
        post :update_status
      end
    end

    resources :version_controls do
			member do
        post :update_status
			end
			resources :version_control_branches
		end
    # member: project id will be passed
    # collection: no project id will be passed
    member do
      get :summary
      post :update_status
			#get :project_stat
			get :dev_stat
			get :issue_stat
    end

		collection do
			post :filter_project
		end
  end

  get "nodes/setup"
  post "nodes/init"

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  root :to => "projects#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
