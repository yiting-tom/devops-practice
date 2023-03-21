# Input Variables

| | |
| --- | --- |
| **Status** | Pending Approval |
| **Author** | [Yi-Ting Li](yiting-tom.github.io) |
| **Version** | 1.0.0 |
| **Last Updated** | 2023-03-21 |
| **Created At** | 2023-03-21 |

## Table of Contents

* [Input Variables](#input-variables)
   * [Introduction](#introduction)
   * [Variable Types](#variable-types)
   * [Variable Defaults](#variable-defaults)
   * [Desription](#desription)
   * [Asserations](#asserations)
   * [Hidden values in CLI output](#hidden-values-in-cli-output)
   * [Cases where Terraform might expose sensitive values](#cases-where-terraform-might-expose-sensitive-values)
   * [Prohibition of Empty Input Variables](#prohibition-of-empty-input-variables)
   * [Assigning Input Variable Values](#assigning-input-variable-values)
      * [Command Line Parameters](#command-line-parameters)
      * [Parameter Files](#parameter-files)
      * [Environment Variables](#environment-variables)
      * [Interactive Interface](#interactive-interface)
      * [Priority of Input Variable Assignment](#priority-of-input-variable-assignment)
      * [Passing values for complex types](#passing-values-for-complex-types)

---

## Introduction

If we imagine a set of Terraform code as a function, input variables are the function's parameters. We can define input variables using a variable block:

```terraform
variable "image_id" {
  type = string
}

variable "availability_zone_names" {
  type    = list(string)
  default = ["us-west-1a"]
}

variable "docker_ports" {
  type = list(object({
    internal = number
    external = number
    protocol = string
  }))

  default = [
    {
      internal = 8300
      external = 8300
      protocol = "tcp"
    }
  ]
}
```

These are all valid input variable definitions. The variable name follows the variable `keyword.` Within a Terraform module (all Terraform code files in the same folder, excluding subfolders), variable names must be unique. We can reference the value of a variable in our code using `var.<NAME>`. There are some keywords that cannot be used as input variable names, such as `source`, `version`, `providers`, `count`, `for_each`, `lifecycle`, `depends_on`, and `locals`.

## Variable Types

We can define the type of an input variable using the `type` attribute. For example:

```terraform
variable "name" {
    type = string
}
variable "ports" {
    type = list(number)
}
```
Input variables with defined types can only be assigned values that conform to the type constraints.

## Variable Defaults

We can define a default value, which Terraform will use if it cannot obtain a value for the input variable. For example:

```terraform
variable "name" {
    type    = string
    default = "John Doe"
}
```

If Terraform cannot obtain a value for `name` through other means, the value of `var.name` will be "John Doe".

## Desription
We can define a description for an input variable to describe its meaning and usage to the caller:

```terraform
variable "image_id" {
  type        = string
  description = "The id of the machine image (AMI) to use for the server."
}
```

If Terraform cannot obtain a value for an input variable during `terraform plan` or `terraform apply`, it will prompt us to set a value for the input variable. We should write input variable descriptions from the perspective of the user rather than the code maintainer. **Descriptions are not comments!**

## Asserations

Input variable assertions are a new feature introduced in Terraform 0.13.0. In the past, Terraform could only use type constraints to ensure that input parameter types were correct.

```terraform
variable "image_id" {
  type        = string
  description = "The id of the machine image (AMI) to use for the server."

  validation {
    condition     = length(var.image_id) > 4 && substr(var.image_id, 0, 4) == "ami-"
    error_message = "The image_id value must be a valid AMI id, starting with \"ami-\"."
  }
}
```

The condition parameter is a `bool` type parameter, and we can use an expression to define how to define a valid input variable. When condition is `true`, the input variable is valid, otherwise it is invalid. In the condition expression, we can only reference the currently defined variable using `var.`, and its calculation cannot produce an error.

If an error in the expression's calculation is a way of judging input variable verification, then we can use the `can` function to determine whether the expression's execution throws an error. For example:

```terraform
variable "image_id" {
  type        = string
  description = "The id of the machine image (AMI) to use for the server."

  validation {
    # regex(...) fails if it cannot find a match
    condition     = can(regex("^ami-", var.image_id))
    error_message = "The image_id value must be a valid AMI id, starting with \"ami-\"."
  }
}
```

In this example, if the input `image_id` does not meet the requirements of the regular expression, the regex function call will throw an error, which will be caught by the can function and output `false`.

If the condition expression is `false`, Terraform will return the error message defined in `error_message`. `error_message` should fully describe the reason for input variable validation failure, as well as the legal constraints for input variables.

## Hidden values in CLI output

Setting a variable as sensitive prevents Terraform from displaying values related to the variable in the output of the plan and apply commands when we use the variable in the configuration file.

Terraform still records sensitive data in the state file, and anyone who can access the state file can read the plaintext sensitive data values.

To declare a variable that contains sensitive data, set the sensitive parameter to true:

```terraform
variable "user_information" {
  type = object({
    name    = string
    address = string
  })
  sensitive = true
}

resource "some_resource" "a" {
  name    = var.user_information.name
  address = var.user_information.address
}
```

Any expression that uses a sensitive variable will be treated as sensitive, so in the example above, the two arguments of resource `some_resource` `a` will also be hidden in the plan output:

Terraform will perform the following actions:

```bash
Terraform will perform the following actions:

  # some_resource.a will be created
  + resource "some_resource" "a" {
      + name    = (sensitive)
      + address = (sensitive)
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```

In some cases, we may use a sensitive variable within a nested block, and Terraform may treat the entire block as sensitive. This happens in resources that contain nested blocks that require unique values, and exposing part of such a nested block's content could imply the content of sibling blocks.

```bash
 # some_resource.a will be updated in-place
  ~ resource "some_resource" "a" {
      ~ nested_block {
          # At least one attribute in this block is (or was) sensitive,
          # so its contents will not be displayed.
        }
    }
```

A provider can also declare a resource property as sensitive, which will cause Terraform to hide it from normal output.

If you intend to use a sensitive value as part of an output value, Terraform will require you to mark the output value itself as sensitive to confirm that you do intend to export it.

## Cases where Terraform might expose sensitive values

Sensitive variables are a configuration-centric concept, and their values are sent to the provider unobscured. If the value is included in an error message, the provider error message might expose the value. For example, even if "foo" is a sensitive value, a provider might return the error "Invalid value 'foo' for field".

If a resource property is used as, or as part of, a provider-defined resource ID, then apply will expose the value. In the following example, the prefix property has been set as a sensitive variable, but then that value ("jae") is exposed as part of the resource ID:

```bash
  # random_pet.animal will be created
  + resource "random_pet" "animal" {
      + id        = (known after apply)
      + length    = 2
      + prefix    = (sensitive)
      + separator = "-"
    }

Plan: 1 to add, 0 to change, 0 to destroy.

...

random_pet.animal: Creating...
random_pet.animal: Creation complete after 0s [id=jae-known-mongoose]
```

## Prohibition of Empty Input Variables

This feature was introduced in Terraform v1.1.0.

The nullable parameter of an input variable controls whether the module caller can assign null to the variable.

```terraform
variable "example" {
  type     = string
  nullable = false 
}
```

nullable defaults to `true`. When nullable is `true`, `null` is a valid value for the variable, and module code must always consider the possibility of the variable being `null`. Passing null as a module input parameter overrides the default value defined on the input variable.

Setting nullable to `false` ensures that the variable value will never be empty within the module. If nullable is `false` and the input variable is defined with a default value, Terraform will use the default value when the module input parameter is `null`.

The nullable parameter only controls the case where the direct value of a variable may be `null`. For collection or object type variables, such as `lists` or `objects`, the caller can still use `null` in collection elements or properties as long as the collection or `object` itself is not `null`.

## Assigning Input Variable Values

### Command Line Parameters

There are several ways to assign values to input variables, one of which is to pass them as parameters when calling the terraform plan or terraform apply command:

```bash
terraform apply -var="image_id=ami-abc123"
terraform apply -var='image_id_list=["ami-abc123","ami-def456"]'
terraform plan -var='image_id_map={"us-east-1":"ami-abc123","us-east-2":"ami-def456"}'
```

Multiple `-var` parameters can be used in a single command.

### Parameter Files

The second method is to use parameter files. The suffix of the parameter file can be `.tfvars` or `.tfvars.json`. The `.tfvars` file uses HCL syntax, while `.tfvars.json` uses JSON syntax.

For example, with `.tfvars`, the parameter file assigns values to the variables that need to be assigned using HCL code:

```terraform
image_id = "ami-abc123"
availability_zone_names = [
  "us-east-1a",
  "us-west-1c",
]
```

For a `.tfvars.json` file, a JSON object is used to assign values to input variables, for example:

```terraform
{
  "image_id": "ami-abc123",
  "availability_zone_names": ["us-west-1a", "us-west-1c"]
}
```

When calling the terraform command, the `-var-file` parameter is used to specify the parameter file to be used, for example:

```bash
terraform apply -var-file="testing.tfvars"
# or
terraform apply -var-file="testing.tfvars.json"
```

There are two cases where the parameter file does not need to be specified:

- If there is a file named `terraform.tfvars` or `terraform.tfvars.json` within the current module
- If there is one or more files with the suffix `.auto.tfvars` or `.auto.tfvars.json` within the current module
Terraform automatically assigns input parameters using these two automatic parameter files.

### Environment Variables

Input variables can be assigned values through environment variables by setting an environment variable named `TF_VAR_<NAME>`, for example:

```bash
export TF_VAR_image_id=ami-abc123
```

On case-sensitive operating systems, Terraform requires that the environment variable name matches the input variable name defined in the Terraform code exactly in terms of capitalization.

Using environment variables for passing values is very useful in automated pipelines, especially for passing sensitive data like passwords, access keys, etc.

### Interactive Interface

As we saw in the example of assertions earlier, when executing Terraform operations from the command line interface, if Terraform cannot obtain a value for an input variable through any other means and that variable does not have a default value defined, Terraform will make a final attempt to ask us for the variable value through an interactive interface.

### Priority of Input Variable Assignment

When multiple assignment methods described above are used simultaneously, the same variable may be assigned a value multiple times. Terraform will use the latest value and overwrite any previous values.

The order in which Terraform loads variable values is:

1. Environment variables
2. `terraform.tfvars` file (if present)
3. `terraform.tfvars.json` file (if present)
4. All `.auto.tfvars` or `.auto.tfvars.json` files, processed in alphabetical order
5. Input variables passed through the `-var` or `-var-file` command-line options, loaded in the order they were defined in the command line

If none of the above methods is successful in assigning a value to a variable, Terraform will attempt to use the default value; for variables with no default value defined, Terraform will prompt the user for a value through the interactive interface. For some Terraform commands, if the `-input=false` option is used to disable interactive interface input, an error will be thrown.

### Passing values for complex types

When passing values through a parameter file, complex types such as lists or maps can be defined directly using HCL or JSON syntax.

For scenarios where using the `-var` command-line option or environment variables is necessary, complex types can be defined using HCL syntax literals enclosed in single quotes, for example:

```bash
export TF_VAR_availability_zone_names='["us-west-1b","us-west-1d"]'
```

Since this method requires manual handling of quote escaping, it is more error-prone, and it is recommended to use parameter files as much as possible for passing values of complex types.