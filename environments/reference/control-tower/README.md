# Control Tower Integration Boundary

## Purpose

This directory contains **architecture metadata** representing the Control Tower
integration strategy. It does NOT deploy Control Tower or any `aws_controltower_*`
resources.

## What This Contains

- Terraform locals modeling governance boundaries
- Governed OU declarations
- Control categories (mandatory, recommended, elective, custom)
- Baseline layer ordering
- Module compatibility assessments
- Ownership boundary declarations
- Tests validating the architecture model

## What This Does NOT Contain

- `aws_controltower_*` resources
- Account Factory / AFT deployment
- Real control identifiers
- AWS API calls
- Real account enrollment

## Usage

```bash
terraform -chdir=environments/reference/control-tower init -backend=false
terraform -chdir=environments/reference/control-tower validate
terraform -chdir=environments/reference/control-tower test
```

## Key Design Points

1. **Suspended OU is NOT governed** — quarantine requires deny-all, not CT enrollment
2. **7 baseline layers** with clear ordering and ownership
3. **CT owns**: org trail, baseline Config, mandatory SCPs, landing zone roles
4. **Terraform owns**: custom SCPs, security services, networking, identity
5. **CloudTrail module becomes optional** when CT org trail is active
6. **Organization module requires adjustment** for CT environments (data sources)
7. **All other modules are compatible** with CT coexistence
