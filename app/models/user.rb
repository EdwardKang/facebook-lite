require "bcrypt"

class User < ActiveRecord::Base
  attr_accessible :email, :password, :first_name, :last_name, :birth_month, :birth_day, :birth_year, :gender
  attr_reader :password
  validates :password_digest, presence: { :message => "Password can't be blank" }
  validates :password, length: { minimum: 6 }
  validates_presence_of :email, :session_token, :first_name, :last_name, :birth_month, :birth_day, :birth_year, :gender
  validates_uniqueness_of :email

  before_validation :reset_session_token!, on: :create

  has_one(
    :profile,
    class_name: 'Profile',
    foreign_key: :user_id,
    primary_key: :id
  )

  has_many(
    :posts,
    class_name: "Post",
    foreign_key: :sender_id,
    primary_key: :id
  )

  has_many(
    :received_posts,
    class_name: "Post",
    foreign_key: :receiver_id,
    primary_key: :id
  )

  has_many(
    :initiated_friendships,
    class_name: "Friendship",
    foreign_key: :friender_id,
    primary_key: :id
  )

  has_many(
    :received_friendships,
    class_name: "Friendship",
    foreign_key: :friendee_id,
    primary_key: :id
  )

  has_many :received_friends, through: :received_friendships, source: :friender
  has_many :initiated_friends, through: :initiated_friendships, source: :friendee

  def friends
    friends = []
    self.received_friends.each do |friend|
      friends << friend unless friend.initiated_friendships.where(is_pending: false, friendee_id: self.id).empty?
    end


    self.initiated_friends.each do |friend|
      friends << friend unless friend.received_friendships.where(is_pending: false, friender_id: self.id).empty?
    end

    friends
  end

  def friends_ids
    friend_ids = []
    self.friends.each do |friend|
      friend_ids << friend.id
    end

    friend_ids
  end

  def no_requests?(user)
    friendship = self.initiated_friendships.where(friendee_id: user.id) + self.received_friendships.where(friender_id: user.id)
    friendship.empty? ? true : false
  end

  def initiated_friend_request(user)
    friendship = self.initiated_friendships.where(friendee_id: user.id, is_pending: true)
    friendship.empty? ? false : friendship[0]
  end

  def received_friend_request(user)
    friendship = self.received_friendships.where(friender_id: user.id, is_pending: true)
    friendship.empty? ? false : friendship[0]
  end

  def initiated_friend?(user)
    !self.initiated_friendships.where(friendee_id: user.id).empty?
  end

  def is_friend(user)
    friendship = self.received_friendships.where(friender_id: user.id) + self.initiated_friendships.where(friendee_id: user.id)
    friendship[0]
  end


  def self.find_by_credentials(email, password)
    user = User.find_by_email(email)
    return nil if user.nil?
    user.is_password?(password) ? user : nil
  end

  def password=(password)
    @password = password
    self.password_digest = BCrypt::Password.create(password)
  end

  def is_password?(password)
    BCrypt::Password.new(self.password_digest).is_password?(password)
  end

  def reset_session_token!
    self.session_token = SecureRandom::urlsafe_base64(16)
  end
end
