module ShopifyApp
  module SessionsController
    extend ActiveSupport::Concern

    def new
      authenticate if params[:shop].present?
    end

    def create
      authenticate
    end

    def callback
      if response = request.env['omniauth.auth']
        sess = ShopifyAPI::Session.new(params[:shop], response['credentials']['token'])
        session[:shopify] = ShopifyApp::SessionRepository.store(sess)
        flash[:notice] = "Logged in"
        redirect_to return_address
      else
        flash[:error] = "Could not log in to Shopify store."
        redirect_to :action => 'new'
      end
    end

    def destroy
      session[:shopify] = nil
      flash[:notice] = "Successfully logged out."

      redirect_to :action => 'new'
    end

    protected

    def authenticate
      if shop_name = sanitize_shop_param(params)
        fullpage_redirect_to "/auth/shopify?shop=#{shop_name}"
      else
        redirect_to return_address
      end
    end

    def return_address
      session[:return_to] || root_url
    end

    def sanitized_shop_name
      @sanitized_shop_name ||= sanitize_shop_param(params)
    end

  def sanitize_shop_param(params)
    return unless params[:shop].present?

    name = params[:shop].to_s.strip
    name += ".myshopify.com" if !name.include?("myshopify.com") && !name.include?(".")
    name.sub!(%r|https?://|, '')

    u = URI("http://#{name}")
    u.host && u.host.ends_with?(".myshopify.com") ? u.host : nil
  rescue URI::InvalidURIError
    nil
  end

  end
end