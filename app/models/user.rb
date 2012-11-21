class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  #devise :database_authenticatable, :registerable,
  #       :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :instagram_id, :instagram_token
  devise :omniauthable

  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session["devise.instagram_data"] && session["devise.instagram_data"]["extra"]["raw_info"]
        #user.email = data["email"] if user.email.blank?
      end
    end
  end

  def self.find_for_instagram_oauth(auth, signed_in_resource=nil)
    user = User.where(:instagram_id => auth.uid).first
    user = User.create(instagram_id: auth.uid, instagram_token: auth.credentials.token) unless user
    user
  end
end
