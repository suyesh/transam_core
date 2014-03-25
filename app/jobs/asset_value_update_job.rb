#------------------------------------------------------------------------------
#
# AssetValueUpdateJob
#
# Updates an assets estimated value
#
#------------------------------------------------------------------------------
class AssetValueUpdateJob < Job
  
  attr_accessor :object_key
  
  def run    
    asset = Asset.find_by_object_key(object_key)
    if asset
      asset.update_estimated_value
    else
      raise RuntimeError, "Can't find Asset with object_key #{object_key}"
    end
  end

  def prepare
    Rails.logger.debug "Executing AssetValueUpdateJob at #{Time.now.to_s} for Asset #{object_key}"    
  end
  
  def check    
    raise ArgumentError, "object_key can't be blank " if object_key.blank?
  end
  
  def initialize(object_key)
    super
    self.object_key = object_key
  end

end