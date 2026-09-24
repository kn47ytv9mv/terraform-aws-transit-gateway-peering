# terraform-aws-transit-gateway-peering

Terraform module for the requester side of a cross-region transit gateway
peering attachment.

## Cost

The peering attachment carries no separate charge — data transferred
across it bills at AWS's standard inter-region data transfer rate, not
the transit gateway's usual per-attachment or per-gigabyte-processing
charge. See AWS's
[Transit Gateway pricing](https://aws.amazon.com/transit-gateway/pricing/)
page for current rates.

## Design

Transit gateway peering is a two-sided operation spanning two regions (or
two accounts), and AWS models it as two distinct resources — this module
creates only the requester side. The peer region must separately accept
the attachment with
[`terraform-aws-transit-gateway-peering-accepter`](https://github.com/kn47ytv9mv/terraform-aws-transit-gateway-peering-accepter),
using this module's `id` output. A peering attachment stays in a
`pendingAcceptance` state, unusable for routing, until the accepter side
runs.

Because the two sides live in different regions, composing them requires
two AWS provider configurations in the same root module — this module
cannot accept both regions itself, since a single provider block can only
target one region.

**Beyond two regions, transit gateway peering is not transitive.** A
peering attachment between region A and region B gives A and B
reachability to each other, and nothing else — a third region C peered
with B does not gain reachability to A through B; A and C need their own
direct peering attachment (and their own `custom_routes` or route table
entries) for A↔C traffic to work at all. For N regions, two topologies
are worth naming explicitly:

- **Full mesh** — every region peers directly with every other:
  N(N-1)/2 peering attachments (3 regions → 3, 5 regions → 10). Every
  region reaches every other in one hop, at the cost of a peering
  attachment (and a module call, on both the requester and accepter
  side) for every pair.
- **Star (hub region)** — every region peers only with one designated
  "core" region: N-1 peering attachments, and every non-core-to-non-core
  path costs an extra hop through the core. Far fewer connections to
  manage, but the core region's transit gateway becomes both a
  bandwidth chokepoint and a single point of failure for all
  non-core-to-non-core traffic.

Full mesh is the safer default while the region count is small (2–4);
past that, weigh the growing N(N-1)/2 connection count against a star's
single-hub risk, or consider
[AWS Cloud WAN](https://aws.amazon.com/cloud-wan/), which provides real
transitive routing across a declared global network instead of
requiring a direct peering attachment for every pair.

**A hub peering with more than ~10 spokes in the same apply can hit AWS's
pending-attachment quota.** AWS caps pending (not-yet-accepted) peering
attachments at 10 per transit gateway — a star hub creating many
requester-side attachments in one apply can transiently exceed it
(`TransitGatewayPeeringLimitExceeded`). Retry the apply once earlier
links have had time to move from `pendingAcceptance` to `available`,
freeing queue slots; the quota is adjustable if this persists at your
region count.

**`available` does not mean traffic is routable yet.** A peering
attachment never auto-propagates routes — both sides need an explicit
static route pointing at the attachment for the peer's CIDR(s), added
via the second example below or
[`terraform-aws-transit-gateway-route-table`](https://github.com/kn47ytv9mv/terraform-aws-transit-gateway-route-table).
`dynamic_routing` exists as an option but is not generally available on
most accounts; leave it null unless yours has it enabled.

## Usage

```hcl
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

provider "aws" {
  alias  = "eu_west_1"
  region = "eu-west-1"
}

module "peering" {
  source = "kn47ytv9mv/transit-gateway-peering/aws"

  providers = { aws = aws.us_east_1 }

  transit_gateway_id      = module.transit_gateway_us_east_1.id
  peer_transit_gateway_id = module.transit_gateway_eu_west_1.id
  peer_region             = "eu-west-1"
}

module "peering_accepter" {
  source = "kn47ytv9mv/transit-gateway-peering-accepter/aws"

  providers = { aws = aws.eu_west_1 }

  transit_gateway_attachment_id = module.peering.id
}
```

Or directly from this repository, with the static routes both sides need
to actually route traffic across the peering (see Design):

```hcl
module "peering" {
  source = "github.com/kn47ytv9mv/terraform-aws-transit-gateway-peering"

  providers = { aws = aws.us_east_1 }

  transit_gateway_id      = module.transit_gateway_us_east_1.id
  peer_transit_gateway_id = module.transit_gateway_eu_west_1.id
  peer_region             = "eu-west-1"
}

resource "aws_ec2_transit_gateway_route" "to_eu_west_1" {
  provider = aws.us_east_1

  transit_gateway_route_table_id = module.transit_gateway_us_east_1.association_default_route_table_id
  destination_cidr_block         = module.vpc_eu_west_1.vpc_cidr_block
  transit_gateway_attachment_id  = module.peering.id
}

resource "aws_ec2_transit_gateway_route" "to_us_east_1" {
  provider = aws.eu_west_1

  transit_gateway_route_table_id = module.transit_gateway_eu_west_1.association_default_route_table_id
  destination_cidr_block         = module.vpc_us_east_1.vpc_cidr_block
  transit_gateway_attachment_id  = module.peering.id
}
```

## Requirements

| Name | Version |
|---|---|
| terraform | >= 1.0 |
| aws | ~> 6.61 |

## Providers

| Name | Version |
|---|---|
| aws | ~> 6.61 |

## Inputs

| Name | Description | Default | Required |
|---|---|---|---|
| transit_gateway_id | The ID of the local transit gateway (in this provider's region) to peer. | `null` | no |
| peer_transit_gateway_id | The ID of the transit gateway to peer with, in the peer region. | `null` | no |
| peer_region | Region of the transit gateway to peer with. | `null` | no |
| peer_account_id | AWS account ID of the transit gateway to peer with, for cross-account peering. If null, defaults to the account this provider is connected to. | `null` | no |
| dynamic_routing | Whether dynamic (BGP-based) routing is used for this peering, instead of static routes. Not generally available on most accounts — see Design. If null, AWS's own default (disabled) applies. | `null` | no |
| tags | A map of tags to assign to the peering attachment. | `null` | no |

## Outputs

| Name | Description |
|---|---|
| id | The ID of the peering attachment. Pass this to `terraform-aws-transit-gateway-peering-accepter`'s `transit_gateway_attachment_id` in the peer region to complete the peering. |
| arn | The ARN of the peering attachment. |
| state | State of the peering attachment (e.g. `'pendingAcceptance'` until accepted, `'available'` once accepted). `'available'` does not mean traffic is routable yet — see Design. |

## License

MIT — see [LICENSE.md](LICENSE.md).
