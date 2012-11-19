class QuipsController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => :create
  # GET /quips
  # GET /quips.xml
  def index
    sort = params[:sort] || session[:sort] || 'newest'
    order = case sort
            when "votes"
              'votes desc'
            when "newest"
              'created_at desc'
            when "oldest"
              'created_at asc'
            end
    sort_changed = sort != session[:sort]
    @quips = Quip.order(order).page(params[:page]).per(15)
    session[:sort] = sort

    respond_to do |format|
      format.html # index.html.erb
      format.js { 
        # If the sort has changed, re-render from page 1; otherwise, 
        # show the next page of results
        js_view_to_render = sort_changed ? :index : :next_page
        @quips.any? ? render(js_view_to_render) : head(:not_found) 
      }
      format.xml  { render :xml => @quips }
    end
  end

  def ajax_autocomplete
    @term = params[:term]
    @results = Quip.search("#{@term}*")
    respond_to do |format|
      format.json { render :json => @results.as_json(:type => :autocomplete) }
    end
  end

  # GET /quips/1
  # GET /quips/1.xml
  def show
    if params[:id] == "random" then
      @quip = Quip.find(:first, :offset => rand(Quip.count))
    else
      @quip = Quip.find(params[:id])
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @quip }
    end
  end

  # GET /quips/new
  # GET /quips/new.xml
  def new
    @quip = Quip.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @quip }
    end
  end

  # GET /quips/1/edit
  def edit
    @quip = Quip.find(params[:id])
  end

  # POST /quips
  # POST /quips.xml
  def create
    params[:quip][:votes] = 0
    @quip = Quip.new(params[:quip])
    should_save = false
    if params[:apikey]
      key = ApiKey.find_by_key(params[:apikey])
      if key
        params[:quip][:submitter] = key.username
        should_save = true
      end
    else
      should_save = verify_recaptcha(@quip)
    end

    respond_to do |format|
      if should_save and @quip.save
        flash[:notice] = 'Quip was successfully created.'
        format.html { redirect_to(@quip) }
        format.xml  { render :xml => @quip, :status => :created, :location => @quip }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @quip.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /quips/1
  # PUT /quips/1.xml
  def update
    @quip = Quip.find(params[:id])

    respond_to do |format|
      if @quip.update_attributes(params[:quip])
        flash[:notice] = 'Quip was successfully updated.'
        format.html { redirect_to(@quip) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @quip.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /quips/1
  # DELETE /quips/1.xml
  def destroy
    @quip = Quip.find(params[:id])
    @quip.destroy

    respond_to do |format|
      format.html { redirect_to(quips_url) }
      format.xml  { head :ok }
    end
  end
  def vote
    if params[:type] == "up" 
      Quip.increment_counter(:votes, params[:id]) 
    elsif params[:type] == "down"
      Quip.decrement_counter(:votes, params[:id]) 
    end
    render :text => Quip.find(params[:id]).votes
  end

  def api_info
  end

  private
  def verify_recaptcha(*args)
    if Rails.env.test?
      true
    else
      super(*args)
    end
  end
end
