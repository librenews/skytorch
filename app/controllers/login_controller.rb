class LoginController < ApplicationController
  layout false
  skip_before_action :authenticate_user!, only: [:index]
  skip_before_action :set_common_variables, only: [:index]

  def index
    # If user is already logged in, redirect to dashboard
    redirect_to dashboard_path if current_user
  end
end

