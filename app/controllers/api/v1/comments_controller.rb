require 'json'
class Api::V1::CommentsController < ApplicationController
  before_action :set_feature

  def create
    raise CommentsExceptionHandler::InvalidFormat if params[:body].nil?

    @comment = @feature.comments.build(body: params[:body])

    if @comment.save
      render json: { message: "Comment created successfully" }, status: :created
    else
      raise "No se pudo guardar el comentario"
    end
  rescue => e
    render json: { error: e.message, instance_errors:  @comment.errors.full_messages }, status: :unprocessable_entity
  end

  private

  def set_feature
    @feature = Feature.find(params[:id])
  end
end
