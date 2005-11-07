class Admin::BanController < ApplicationController
	before_filter :login_required  
  
  def index
    list
    render :action => 'list'
  end

  def list
    @ban_pages, @bans = paginate :ban, :per_page => 10
  end

  def show
    @ban = Ban.find(params[:id])
  end

  def new
    @ban = Ban.new
  end

  def create
    @ban = Ban.new(params[:ban])
    if @ban.save
      flash[:notice] = 'Ban was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @ban = Ban.find(params[:id])
  end

  def update
    @ban = Ban.find(params[:id])
    if @ban.update_attributes(params[:ban])
      flash[:notice] = 'Ban was successfully updated.'
      redirect_to :action => 'show', :id => @ban
    else
      render :action => 'edit'
    end
  end

  def destroy
    Ban.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
