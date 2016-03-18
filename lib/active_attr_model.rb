# A copy of ActiveAttr::Model without its override of the 'logger' method.
module ActiveAttrModel
  extend ActiveSupport::Concern
  include ActiveAttr::BasicModel
  include ActiveAttr::BlockInitialization
  include ActiveAttr::MassAssignment
  include ActiveAttr::AttributeDefaults
  include ActiveAttr::QueryAttributes
  include ActiveAttr::TypecastedAttributes
  include ActiveAttr::Serialization
end
