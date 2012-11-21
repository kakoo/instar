class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def instagram
    if env['omniauth.error'].nil?
      user = User.find_for_instagram_oauth(request.env["omniauth.auth"], current_user)

      if user.persisted?
        sign_in user
      else
        session["devise.instagram_data"] = request.env["omniauth.auth"]
      end
      redirect_to "/"

    else
      # error
      # 인증 실패
    end

  end

  def passthru

  end
end