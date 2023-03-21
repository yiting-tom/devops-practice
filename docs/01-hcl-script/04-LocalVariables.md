# Local Variables

| | |
| --- | --- |
| **Status** | Pending Approval |
| **Author** | [Yi-Ting Li](yiting-tom.github.io) |
| **Version** | 1.0.0 |
| **Last Updated** | 2023-03-21 |
| **Created At** | 2023-03-21 |

---

Sometimes we need to calculate a value using a complex expression and use it repeatedly. In this case, we can assign the complex expression to a `local` value and refer to it multiple times. If `input` variables are like function parameters and `output` values are like function return values, then `local` values are like local variables defined inside a function.

Local values are defined using the locals block, for example:

```terraform
locals {
    service_name = "forum"
    owner = "Community Team"
}
```

A locals block can define multiple local values, and we can define any number of locals blocks. `local` values can be assigned with more complex expressions, other data or resource outputs, input variables, or even other local values:

```terraform
locals {
  # Ids for multiple sets of EC2 instances, merged together
  instance_ids = concat(aws_instance.blue.*.id, aws_instance.green.*.id)
}

locals {
  # Common tags to be assigned to all resources
  common_tags = {
    Service = local.service_name
    Owner   = local.owner
  }
}
```

To reference a `local` value, we use the expression `local.<NAME>` (note that even though local values are defined in the locals block, we use local to refer to them, not locals), for example:

```terraform
resource "aws_instance" "example" {
  # ...

  tags = local.common_tags
}
```

Local values can only be referenced within the same module.

⚠️ Local values can help us avoid repeating complex expressions and improve code readability, but if overused, they can increase code complexity and make it harder for maintainers to understand the expressions and values used. We should use local values moderately and only for scenarios where we need to repeatedly reference the same complex expression. In the future, local values will make it much easier to modify the expression if needed.
