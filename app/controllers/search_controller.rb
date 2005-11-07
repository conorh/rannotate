class SearchController < ApplicationController
  layout "doc"

  def search_by_name
    name = '%' + params[:name].downcase + '%'
    
    @results = Hash.new   
    
    temp = RaContainer.find(:all, :conditions => ["lower(name) like ?", name])    
    temp.push(RaMethod.find(:all, :conditions => ["lower(name) like ?", name]))
    temp.push(RaCodeObject.find(:all, :conditions => ["lower(name) like ?", name]))
    
    # Create a hash of the results
    temp.each do |obj| 
      unless @results.has_key?(obj.class) then @results[obj.class] = [] end
      @results[obj.class].push(obj)
    end 
    
    render :partial => "search_results"
    
  end

end
