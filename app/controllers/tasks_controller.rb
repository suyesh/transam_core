class TasksController < OrganizationAwareController
  
  before_action :set_task, :only => [:show, :edit, :update, :destroy, :update_status]  
  before_filter :check_for_cancel, :only => [:create, :update] 

  SESSION_VIEW_TYPE_VAR = 'tasks_subnav_view_type'
  
  # Ajax callback returning a list of tasks as JSON calendar events
  def filter
    filter_start_time = DateTime.strptime(params[:start], '%s')
    filter_end_time   = DateTime.strptime(params[:end], '%s')
    
    tasks = Task.where("assigned_to_user_id = ? AND complete_by BETWEEN ? AND ?", current_user.id, filter_start_time, filter_end_time).order("complete_by")
    events = []
    tasks.each do |t|
      events << {
        :id => t.id,
        :title => t.subject,
        :allDay => false,
        :start => t.complete_by,
        :url => user_task_path(current_user, t),
        :color => get_event_color(t)
      }
    end

    Rails.logger.debug events.inspect
    
    respond_to do |format|
      format.json { render :json => events }
    end
  end
  
  def index

    @page_title = 'Tasks'
    # Select tasks for this user or ones that are for the agency as a whole
    @tasks = Task.where("for_organization_id = ? AND completed_on IS NULL AND (assigned_to_user_id IS NULL OR assigned_to_user_id = ?)", @organization.id, current_user.id).order("complete_by")
    
    # remember the view type
    @view_type = get_view_type(SESSION_VIEW_TYPE_VAR)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @tasks }
    end
  end

  def show

    # if not found or the object does not belong to the users
    # send them back to index.html.erb
    if @task.nil?
      notify_user(:alert, "Record not found!")
      redirect_to user_tasks_url
      return
    end
 
    @page_title = 'Task'
    
    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @task }
    end
  end

  def new

    @page_title = 'New Task'

    @task = Task.new
    @task.from_organization = @organization
    @task.from_user = current_user
    @task.complete_by = Date.today + 1
    @task.priority_type = PriorityType.default
    
    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @task }
    end
  end

  def edit

    # if not found or the object does not belong to the users
    # send them back to index.html.erb
    if @task.nil?
      notify_user(:alert, "Record not found!")
      redirect_to user_tasks_url
      return
    end

  end

  def create

    @task = Task.new(form_params)
    # Simple form doesn't process mapped assoacitions very well
    @task.assigned_to = User.find(params[:task][:assigned_to_user_id]) unless params[:task][:assigned_to_user_id].blank?
    @task.for_organization = @task.assigned_to.organization unless @task.assigned_to.nil?
    
    @task.from_organization = @organization
    @task.from_user = current_user

    respond_to do |format|
      if @task.save
        notify_user(:notice, "Task was successfully created.")
        format.html { redirect_to user_tasks_url(current_user) }
        format.json { render :json => @task, :status => :created, :location => @task }
      else
        format.html { render :action => "new" }
        format.json { render :json => @task.errors, :status => :unprocessable_entity }
      end
    end

  end

  def update_status

    # if not found or the object does not belong to the users
    # send them back to index.html.erb
    if @task.nil?
      notify_user(:alert, "Record not found!")
      redirect_to user_tasks_url
      return
    end

    @task.task_status_type = TaskStatusType.find(params[:task_status])
    if @task.task_status_type.name == 'Complete'
      @task.completed_on = Date.today
    else 
      @task.completed_on = nil
    end
    
    respond_to do |format|
      if @task.save
        notify_user(:notice, "Task was successfully updated.")
        format.html { redirect_to user_task_url(current_user, @task) }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @task.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update

    # if not found or the object does not belong to the users
    # send them back to index.html.erb
    if @task.nil?
      notify_user(:alert, "Record not found!")
      redirect_to user_tasks_url
      return
    end

    respond_to do |format|
      if @task.update_attributes(form_params)
        notify_user(:notice, "Task was successfully updated.")
        format.html { redirect_to user_tasks_url(current_user) }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @task.errors, :status => :unprocessable_entity }
      end
    end
  end

  #------------------------------------------------------------------------------
  #
  # Protected Methods
  #
  #------------------------------------------------------------------------------
  protected
  
  def get_event_color(task)
    if task.priority_type == 1
      color = '#FF0000'
    elsif task.priority_type == 2
      color = '#00FF00'
    else
      color = '00FFFF'
    end
    color
  end
  
  #------------------------------------------------------------------------------
  #
  # Private Methods
  #
  #------------------------------------------------------------------------------
  private

  def check_for_cancel
    unless params[:cancel].blank?
      # check that the user has access to this agency
      redirect_to(user_tasks_url(current_user))
    end
  end 
  
  # Callbacks to share common setup or constraints between actions.
  def set_task
    @task = params[:id].nil? ? nil : Task.find_by_object_key(params[:id])
  end

  # make sure that only tasks for this user or unassigned tasks for this agency are viewed or edited
  def find_task(task_id)
    Task.where("id = ? AND for_organization_id = ? AND (assigned_to_user_id IS NULL OR assigned_to_user_id = ?)", task_id, @organization.id, current_user.id).first
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def form_params
    params.require(:task).permit(task_allowable_params)
  end
  
end
