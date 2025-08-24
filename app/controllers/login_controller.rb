class LoginController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index]

  def index
    # If user is already logged in, redirect to dashboard
    redirect_to dashboard_path if current_user
  end
end

