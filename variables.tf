variable "transit_gateway_id" {
  default     = null
  description = "The ID of the local transit gateway (in this provider's region) to peer."
}

variable "peer_transit_gateway_id" {
  default     = null
  description = "The ID of the transit gateway to peer with, in the peer region."
}

variable "peer_region" {
  default     = null
  description = "Region of the transit gateway to peer with."
}

variable "peer_account_id" {
  default     = null
  description = "AWS account ID of the transit gateway to peer with, for cross-account peering. If null, defaults to the account this provider is connected to."
}

variable "dynamic_routing" {
  default     = null
  description = "Whether dynamic (BGP-based) routing is used for this peering, instead of static routes. Not generally available on most accounts — see Design. If null, AWS's own default (disabled) applies."
}

variable "tags" {
  default     = null
  description = "A map of tags to assign to the peering attachment."
}
