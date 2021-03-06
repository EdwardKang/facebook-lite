class Comment < ActiveRecord::Base
  attr_accessible :body, :post_id, :user_id
  validates_presence_of :body, :post_id, :user_id

  belongs_to(
    :post,
    class_name: "Post",
    foreign_key: :post_id,
    primary_key: :id
  )

  belongs_to(
    :user,
    class_name: "User",
    foreign_key: :user_id,
    primary_key: :id
  )

  has_many :likes, as: :likeable, dependent: :destroy
  has_many :notifications, as: :notifiable, dependent: :destroy
end