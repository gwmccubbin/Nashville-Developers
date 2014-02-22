class Authorization < ActiveRecord::Base  
  belongs_to :user
  attr_accessible :provider, :user_id, :token, :secret

  scope :facebook, where(provider: :facebook)
  scope :twitter, where(provider: :twitter)
  scope :with_user, includes(:user)
  scope :for_user, ->(user) { where(user_id: user) }
  scope :for_uid, ->(user_id) { where(user_id: user_id) }

  class << self
    def get_facebook_user(external_id)
      facebook.with_user.for_uid(external_id).first
    end

    def get_twitter_user(external_id)
      twitter.with_user.for_uid(external_id).first
    end

    def get_facebook_token_for_user(user)
      facebook.for_user(user).first.try(:token)
    end

    def get_twitter_token_for_user(user)
      twitter.for_user(user).first.try(:token)
    end
  end
end
