resource "aws_ec2_transit_gateway_peering_attachment" "resource" {
  transit_gateway_id      = var.transit_gateway_id
  peer_transit_gateway_id = var.peer_transit_gateway_id
  peer_region             = var.peer_region
  peer_account_id         = var.peer_account_id

  dynamic "options" {
    for_each = var.dynamic_routing[*]

    content {
      dynamic_routing = options.value ? "enable" : "disable"
    }
  }

  tags = merge(var.tags, { name = "peering" })
}

output "id" {
  description = "The ID of the peering attachment. Pass this to terraform-aws-transit-gateway-peering-accepter's transit_gateway_attachment_id in the peer region to complete the peering."
  value       = aws_ec2_transit_gateway_peering_attachment.resource.id
}

output "arn" {
  description = "The ARN of the peering attachment."
  value       = aws_ec2_transit_gateway_peering_attachment.resource.arn
}

output "state" {
  description = "State of the peering attachment (e.g. 'pendingAcceptance' until accepted, 'available' once accepted). 'available' does not mean traffic is routable yet — see the README's Design section."
  value       = aws_ec2_transit_gateway_peering_attachment.resource.state
}
