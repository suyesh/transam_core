class AssetEventsController < AssetAwareController

  add_breadcrumb "Home", :root_path

  # set the @asset_event variable before any actions are invoked
  before_filter :get_asset_event,       :only => [:show, :edit, :update, :destroy]  
  before_filter :check_for_cancel,      :only => [:create, :update]
  before_filter :reformat_date_field,   :only => [:create, :update]

  # always use generic untyped assets for this controller
  RENDER_TYPED_ASSETS = true
    
  # always render untyped assets for this controller
  def render_typed_assets
    RENDER_TYPED_ASSETS
  end

  def index

    # Check to see if we got a filter to sub select on
    if params[:filter_type]
      # see if it was blank
      if params[:filter_type].blank?
        @filter_type = 0
      else
        @filter_type = params[:filter_type].to_i
      end
    else
      # See if there is one in the session
      @filter_type = session[:filter_type].nil? ? 0 : session[:filter_type]
    end
    # store it in the session
    session[:filter_type] = @filter_type

    if @filter_type == 0
      @events = @asset.asset_events
    else
      @events = @asset.asset_events.where('asset_event_type_id = ?', @filter_type)
    end
         
    @page_title = "#{@asset.name}: History"
    
    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @events }
    end

  end
  
  def new
        
    # get the asset event type
    asset_event_type = AssetEventType.find(params[:event_type])
    if asset_event_type
      @asset_event = AssetEvent.get_new_typed_event(asset_event_type)
    end

    @page_title = "#{@asset.name}: New #{@asset_event.asset_event_type.name}"
    add_breadcrumb "#{@asset.asset_type.class_name.underscore.humanize.titleize}".pluralize(2), inventory_index_path(:asset_type => @asset.asset_type, :asset_subtype => 0)
    add_breadcrumb "#{@asset.asset_subtype.name}", inventory_index_path(:asset_subtype => @asset.asset_subtype)
    add_breadcrumb @asset.asset_tag, inventory_path(@asset)    
    add_breadcrumb @asset_event.asset_event_type.name, new_inventory_asset_event_path(@asset)    

    respond_to do |format|
      format.html 
      format.json { render :json => @asset_event }
    end
    
  end

  def show

    # if not found or the object does not belong to the asset
    # send them back to index.html.erb
    if @asset_event.nil?
      notify_user(:alert, 'Record not found!')
      redirect_to(inventory_url(@asset))
      return
    end
 
    @page_title = "#{@asset.name}: #{@asset_event.asset_event_type.name}: #{localize(@asset_event.event_date)}"
    @disabled = true
    
    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @asset_event }
    end
  end

  def edit

    # if not found or the object does not belong to the asset
    # send them back to index.html.erb
    if @asset_event.nil?
      notify_user(:alert, 'Record not found!')
      redirect_to(inventory_url(@asset))
      return
    end

    @page_title = "#{@asset.name}: Update #{@asset_event.asset_event_type.name}"
    @disabled = false
   
  end
  
  def update

    # if not found or the object does not belong to the asset
    # send them back to index.html.erb
    if @asset_event.nil?
      notify_user(:alert, 'Record not found!')
      redirect_to(inventory_url(@asset))
      return
    end

    respond_to do |format|
      if @asset_event.update_attributes(form_params)

        notify_user(:notice, "Event was successfully updated.")   

        # The event was updated so we need to update the asset.
        fire_asset_update_event(@asset_event.asset_event_type, @asset)
             
        format.html { redirect_to inventory_url(@asset) }
        format.json { head :no_content }
      else
        format.html { render "edit" }
        format.json { render :json => @asset_event.errors, :status => :unprocessable_entity }
      end
    end
  end

  def create

    # we need to know what the event type was for this event
    asset_event_type = AssetEventType.find(params[:event_type])
    # get the class name for this asset event type
    class_name = asset_event_type.class_name
    klass = Object.const_get class_name    
    @asset_event = klass.new(form_params)
    @asset_event.asset = @asset
    
    Rails.logger.debug @asset_event.inspect
    
    respond_to do |format|
      if @asset_event.save
        
        notify_user(:notice, "Event was successfully created.")   

        # The event was removed so we need to update the asset 
        fire_asset_update_event(@asset_event.asset_event_type, @asset)
                
        format.html { redirect_to inventory_url(@asset) }
        format.json { render :json => @asset_event, :status => :created, :location => @asset_event }
      else
        Rails.logger.debug @asset_event.errors.inspect
        format.html { render :action => "new" }
        format.json { render :json => @asset_event.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy

    # if not found or the object does not belong to the asset
    # send them back to index.html.erb
    if @asset_event.nil?
      notify_user(:alert, 'Record not found!')
      redirect_to(inventory_url(@asset))
      return
    end

    asset_event_type = @asset_event.asset_event_type
    @asset_event.destroy

    notify_user(:notice, "Event was successfully removed.")   

    # The event was removed so we need to update the asset condition
    fire_asset_update_event(asset_event_type, @asset)

    respond_to do |format|
      format.html { redirect_to(inventory_url(@asset)) } 
      format.json { head :no_content }
    end
  end
  
  #------------------------------------------------------------------------------
  #
  # Protected Methods
  #
  #------------------------------------------------------------------------------
  protected
  
  # Updates the asset by firing a background job to update the asset. The job is based on the
  # type of event that was modified
  def fire_asset_update_event(asset_event_type, asset, priority = 0)
    if asset_event_type and asset
      klass = asset_event_type.job_name.constantize
      job = klass.new(asset.object_key)
      fire_background_job(job, priority)
    end
  end
  
  
  def get_asset_event
    asset_event = AssetEvent.find_by_object_key(params[:id]) unless params[:id].nil?
    if asset_event
      @asset_event = AssetEvent.as_typed_event(asset_event)
    end
  end

  #------------------------------------------------------------------------------
  #
  # Private Methods
  #
  #------------------------------------------------------------------------------
  private

  def reformat_date_field
    date_str = params[:asset_event][:event_date]
    form_date = Date.strptime(date_str, '%m-%d-%Y')
    params[:asset_event][:event_date] = form_date.strftime('%Y-%m-%d')
  end
  
  # Never trust parameters from the scary internet, only allow the white list through.
  def form_params
    params.require(:asset_event).permit(asset_event_allowable_params)
  end
  
  def check_for_cancel
    # go back to the asset view
    unless params[:cancel].blank?
      redirect_to(inventory_url(@asset))
    end    
  end
    
end
