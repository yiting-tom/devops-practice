# Outputs

| | |
| --- | --- |
| **Status** | Pending Approval |
| **Author** | [Yi-Ting Li](yiting-tom.github.io) |
| **Version** | 1.0.0 |
| **Last Updated** | 2023-03-21 |
| **Created At** | 2023-03-21 |

## Table of Contents

* [Outputs](#outputs)
   * [Declaring Outputs](#declaring-outputs)
      * [Description](#description)
      * [Sensitive](#sensitive)
      * [Depends_on](#depends_on)
      * [Precondition](#precondition)

---

## Declaring Outputs

To declare an output value, we use an output block, like this:

```terraform
output "instance_ip_addr" {
    value = aws_instance.example.public_ip
}
```

The keyword `output` is followed by the name of the output value. All output names in the current module must be **unique**. The value parameter inside the output block is the output value, which can be a property of a resource like in the example above or any valid expression.

Output values are only computed after running `terraform apply`. Simply running `terraform plan` will not compute output values.

Output values defined in the current directory cannot be referenced in Terraform code.

### Description

Same as the description of the input variable block.

### Sensitive

An output value can be marked as sensitive by setting `sensitive=true`, indicating that the output value contains sensitive information. An output value marked as sensitive will be printed as "" instead of the actual output value upon a successful terraform apply command, and will also print "" when running the terraform output command. However, the actual sensitive value can still be seen by executing `terraform output -json`.

⚠️ It's important to note that even when an output value is marked as sensitive, it will still be recorded in the **state file**, and anyone with permission to read the state file can still access the sensitive data.

### Depends_on

The content about `depends_on` will be explained in detail in the `resource` section, so here we only provide a rough introduction.

Terraform analyzes the dependencies between various data and resources defined in the code. For example, when creating a virtual machine, the `image_id` parameter used is obtained through a data query. The virtual machine instance depends on the data for this image, so Terraform will create the data first, obtain the query result, and then create the virtual machine resource. Generally, the creation order between data and resource is automatically calculated by Terraform and does not need to be explicitly specified by the code writer. However, sometimes there are dependencies that cannot be derived by analyzing the code. In such cases, we can declare the dependency relationship explicitly in the code using `depends_on`.

In general, output rarely needs to explicitly depend on certain resources. However, in some special scenarios, such as when calling a module in the current code (which can be understood as calling Terraform code in another directory to create some resources), the caller wants to continue the subsequent creation work only after all module resources have been created. In this case, we can design an output for the module, explicitly declare the dependency relationship using `depends_on`, and ensure that the output must be read only after all module resources have been successfully created. This way, we can control the creation order of resources at the module scale.

The usage of `depends_on` is as follows:

```terraform
output "instance_ip_addr" {
    value = aws_instance.server.private_ip
    description = "The private IP address of the main server instance."

    depends_on = [
        # Security group rule must be created before this IP address could
        # actually be used, otherwise the services will be unreachable.
        aws_security_group_rule.local_access,
    ]
}
```

We do not encourage defining depends_on for output, and it should only be used as a last resort. If you have to define depends_on for output, be sure to explain the reason in comments to facilitate maintenance by future developers.

### Precondition

Output blocks can include a `precondition` block starting from Terraform v1.2.0.

The `precondition` block on the output block corresponds to the `validation` block in the `variable` block. The `validation` block checks whether the input variable value meets the module's requirements, while the `precondition` ensures that the output values of the module meet certain requirements. We can use `precondition` to prevent Terraform from writing an invalid output value to the **state file**. We can use `precondition` to protect the valid output values left by the last apply in appropriate scenarios.

Terraform performs precondition checking on the output block before evaluating the value expression of the output value. This can prevent potential errors in the value expression from being triggered.
