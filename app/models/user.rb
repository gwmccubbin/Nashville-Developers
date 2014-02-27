class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable
 	attr_accessible :first_name, :last_name, :email, :password

 	has_many :authorizations, :dependent => :destroy  

  def full_name
  	"#{first_name} #{last_name}"
  end

  def facebook_token
    @facebook_token ||= self.authorizations.get_facebook_token_for_user(self)
  end

  def twitter_token
    @twitter_token ||= self.authorizations.get_twitter_token_for_user(self)
  end

  def add_authorization_for_facebook(uid, auth_token)
    add_authorization(:facebook, uid, auth_token)
  end

  def add_authorization_for_twitter(uid, auth_token, auth_secret)
    add_authorization(:twitter, uid, auth_token, auth_secret)
  end

  def add_authorization(provider, uid, auth_token, auth_secret = nil)
    self.authorizations.build(provider: provider, user_id: uid, token: auth_token, secret: auth_secret)
  end

  class << self
    def find_or_create_by_facebook_oauth(auth, signed_in_resource = nil)
      authorization = Authorization.get_facebook_user(auth.uid)
      user = authorization.try(:user)

      if signed_in_resource
        unless signed_in_resource == user
          signed_in_resource.add_authorization_for_facebook(auth.uid, auth.credentials.try(:token))
          signed_in_resource.save
        end

        return signed_in_resource
      end

      unless user
        user = User.create(first_name: auth.extra.raw_info.first_name,
                           last_name: auth.extra.raw_info.last_name,
                           email: auth.info.email,
                           password: Devise.friendly_token[0,20])

        user.add_authorization_for_facebook(auth.uid, auth.credentials.try(:token))
      end
      user
    end

    def find_or_create_by_twitter_oauth(auth, signed_in_resource = nil)
      authorization = Authorization.get_twitter_user(auth.uid)
      user = authorization.try(:user)

      if signed_in_resource
        unless signed_in_resource == user
          signed_in_resource.add_authorization_for_twitter(auth.uid, auth.credentials.try(:token), auth.credentials.try(:secret))
          signed_in_resource.save
        end

        return signed_in_resource
      end

      unless user
        first_name = auth.extra.raw_info.name.slice(/\A(\w*)\b/)
        user = User.create(first_name: first_name,
                           email: "#{first_name}@isignedupwithtwitter.com",
                           password: Devise.friendly_token[0,20])

        user.add_authorization_for_twitter(auth.uid, auth.credentials.try(:token), auth.credentials.try(:secret))
      end
      user
    end
  end
end
