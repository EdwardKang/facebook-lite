class CommentsController < ApplicationController
  before_filter :require_user!

  def create
    @comment = Comment.new(params[:comment])
    @comment.post_id = params[:post_id]
    @comment.save
    redirect_to :back
  end
end
