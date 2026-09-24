mock_provider "aws" {
}

run "required_arguments_pass_through" {
  command = plan

  variables {
    transit_gateway_id      = "tgw-0123456789abcdef0"
    peer_transit_gateway_id = "tgw-0fedcba9876543210"
    peer_region             = "eu-west-1"
  }

  assert {
    condition     = aws_ec2_transit_gateway_peering_attachment.resource.transit_gateway_id == "tgw-0123456789abcdef0"
    error_message = "transit_gateway_id should pass through unchanged."
  }

  assert {
    condition     = aws_ec2_transit_gateway_peering_attachment.resource.peer_transit_gateway_id == "tgw-0fedcba9876543210"
    error_message = "peer_transit_gateway_id should pass through unchanged."
  }

  assert {
    condition     = aws_ec2_transit_gateway_peering_attachment.resource.peer_region == "eu-west-1"
    error_message = "peer_region should pass through unchanged."
  }

  assert {
    condition     = length(aws_ec2_transit_gateway_peering_attachment.resource.options) == 0
    error_message = "dynamic_routing was not set, so no options block should be rendered."
  }
}

run "dynamic_routing_true_renders_enable" {
  command = plan

  variables {
    transit_gateway_id      = "tgw-0123456789abcdef0"
    peer_transit_gateway_id = "tgw-0fedcba9876543210"
    peer_region             = "eu-west-1"
    dynamic_routing         = true
  }

  assert {
    condition     = aws_ec2_transit_gateway_peering_attachment.resource.options[0].dynamic_routing == "enable"
    error_message = "dynamic_routing = true should render options.dynamic_routing = 'enable'."
  }
}

run "dynamic_routing_false_renders_disable" {
  command = plan

  variables {
    transit_gateway_id      = "tgw-0123456789abcdef0"
    peer_transit_gateway_id = "tgw-0fedcba9876543210"
    peer_region             = "eu-west-1"
    dynamic_routing         = false
  }

  assert {
    condition     = aws_ec2_transit_gateway_peering_attachment.resource.options[0].dynamic_routing == "disable"
    error_message = "dynamic_routing = false should render options.dynamic_routing = 'disable'."
  }
}

run "peer_account_id_passes_through_when_set" {
  command = plan

  variables {
    transit_gateway_id      = "tgw-0123456789abcdef0"
    peer_transit_gateway_id = "tgw-0fedcba9876543210"
    peer_region             = "eu-west-1"
    peer_account_id         = "123456789012"
  }

  assert {
    condition     = aws_ec2_transit_gateway_peering_attachment.resource.peer_account_id == "123456789012"
    error_message = "peer_account_id should pass through unchanged when set."
  }
}

run "readme_default_example" {
  command = plan

  variables {
    transit_gateway_id      = "tgw-0123456789abcdef0"
    peer_transit_gateway_id = "tgw-0fedcba9876543210"
    peer_region             = "eu-west-1"
  }
}

