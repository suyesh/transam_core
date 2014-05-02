class CommentsController < NestedResourceController
  before_action :set_comment, :only => [:edit, :update, :destroy]

  # GET /comments
  # GET /comments.json
  def index
       
    @commentable = find_resource
    @comments = @commentable.comments
  
    @page_title = "#{@commentable.name}: Comments"

  end

  # GET /comments/1
  # GET /comments/1.json
  def show
  end

  # GET /comments/new
  def new
    @comment = Comment.new
    @commentable = find_resource
    @page_title = "#{@commentable.name}: New comment"
  end

  # GET /comments/1/edit
  def edit

    @commentable = @comment.commentable
    @page_title = "#{@commentable.name}: Edit comment"

  end

  # POST /comments
  # POST /comments.json
  def create
    @commentable = find_resource
    @comment = @commentable.comments.build(comment_params)
    @comment.creator = current_user
    @page_title = "#{@commentable.name}: New comment"
    
    respond_to do |format|
      if @comment.save
        notify_user(:notice, 'Comment was successfully created.')
        format.html { redirect_to get_resource_url(@commentable) }
        format.json { render action: 'show', status: :created, location: @comment }
      else
        format.html { render action: 'new' }
        format.json { render json: @comment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /comments/1
  # PATCH/PUT /comments/1.json
  def update

    @commentable = @comment.commentable
    @page_title = "#{@commentable.name}: Edit comment"

    respond_to do |format|
      if @comment.update(comment_params)
        notify_user(:notice, 'Comment was successfully updated.')   
        format.html { redirect_to get_resource_url(@commentable) }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @comment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /comments/1
  # DELETE /comments/1.json
  def destroy

    @commentable = @comment.commentable    
    @comment.destroy
    
    notify_user(:notice, 'Comment was successfully removed.')   
    respond_to do |format|
      format.html { redirect_to get_resource_url(@commentable) }
      format.json { head :no_content }
    end
  end

  private
    
  # Use callbacks to share common setup or constraints between actions.
  def set_comment
    @comment = Comment.find_by_object_key(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def comment_params
    params.require(:comment).permit(comment_allowable_params)
  end

end