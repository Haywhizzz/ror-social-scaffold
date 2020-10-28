class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :name, presence: true, length: { maximum: 20 }
  validates :email, :password, presence: true

  has_many :posts
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :friendships
  has_many :confirmed_friendships, -> { where confirmed: true }, class_name: 'Friendship'
  has_many :friends, through: :confirmed_friendships
  has_many :pending_friendships, -> { where confirmed: false }, class_name: 'Friendship', foreign_key: 'user_id'
  has_many :pending_friends, through: :pending_friendships, source: :friend
  has_many :inverted_friendships, -> { where confirmed: false }, class_name: 'Friendship', foreign_key: 'friend_id'
  has_many :friend_requests, through: :inverted_friendships, source: :user

  def confirm_friend(user)
    friend = Friendship.find_by(user_id: user.id, friend_id: id)
    friend.confirmed = true
    friend.save
    Friendship.create!(friend_id: user.id, user_id: id, confirmed: true)
  end

  def reject_request(user)
    friendship = inverted_friendships.find { |f| f.user == user }
    friendship.destroy
  end

  def friend_with?(user)
    Friendship.confirmed_record?(id, user.id)
  end

  def send_friendship(_user)
    friendships.create(friend_id(:user.id))
  end

  def friend?(user)
    friends.include?(user)
  end

  def friends_and_own_posts
    Post.where(user_id: friend_ids)
  end
end
