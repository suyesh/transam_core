class AssetAgeReport < AbstractReport

  def initialize(attributes = {})
    super(attributes)
  end    
  
  def get_data(organization, params)

    # Check to see if we got an asset type to sub select on
    if params[:report_filter_type] 
      report_filter_type = params[:report_filter_type].to_i
    else
      report_filter_type = 0
    end
    
    a = []
    labels = ['Age (Years)']

    AssetType.all.each do |type| 
      labels << type.name
    end
        
    (1..MAX_REPORTING_YEARS).each do |year|
      counts = []
      counts << year.to_s
      manufacture_year = year.year.ago
      AssetType.all.each do |type| 
        counts << organization.assets.where("asset_type_id = ? AND manufacture_year = ?", organization.id, type.id, manufacture_year).count
      end
      a << counts
    end

    # get the bucket for MAX_YEARS+ years old
    year = MAX_REPORTING_YEARS
    counts = []
    counts << year.to_s
    manufacture_year = MAX_REPORTING_YEARS.year.ago
    AssetType.all.each do |type| 
      counts << organization.assets.where("asset_type_id = ? AND manufacture_year < ?", organization.id, type.id, manufacture_year).count
    end
    a << counts
        
    return {:labels => labels, :data => a}

  end
  
end
