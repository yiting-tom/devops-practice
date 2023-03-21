# Configuration Syntax

| | |
| --- | --- |
| **Status** | Pending Approval |
| **Author** | [Yi-Ting Li](yiting-tom.github.io) |
| **Version** | 1.0.0 |
| **Last Updated** | 2023-03-21 |
| **Created At** | 2023-03-21 |

## Table of Contents

* [Configuration Syntax](#configuration-syntax)
   * [Arguments](#arguments)
   * [Blocks](#blocks)
   * [Identifiers](#identifiers)
   * [Comments](#comments)
   * [Encoding and Line Breaks](#encoding-and-line-breaks)

---

## Arguments

Parameter assignment is simply assigning a value to a specific named parameter. For example, to assigns the value `1` to the parameter `a`, we simply use `a = 1` to do.

The identifier before the equal sign is the parameter name, and the expression after the equal sign is the parameter value. Terraform checks whether the type matches when assigning values to parameters. The parameter name is determined, and the parameter value can be a determined literal hard-coded, or a set of expressions that are calculated based on other values.

## Blocks
A block is a container that contains a group of other content, for example:
```terraform
resource "aws_instance" "example" {
  ami           = "ami-2757f631"
  instance_type = "t2.micro"

  network_interface {
    device_index         = 0
    network_interface_id = "eni-12345678"
  }
}
```
A block has a type (the type in the example above is resource). Each block type defines how many labels must follow the type keyword. For example, the resource block specifies that two labels must follow - aws_instance and example in this example. A block type can specify any number of labels, or no labels, such as the embedded network_interface block.

After the block type and its subsequent label, there is the block body. The block body must be enclosed in a pair of braces. Various parameters and other blocks can be further defined in the block body.

Terraform specifications define a limited number of top-level block types, that is, blocks that can be defined independently in the configuration file, without depending on any other block. Most of Terraform's features (such as resource, variable, output, data, etc.) are top-level blocks.

## Identifiers
Parameter names, block type names, and the names of other structures defined in the Terraform specification, such as resource, variable, etc., are all identifiers.

Valid identifiers can contain letters, numbers, underscores (_), and hyphens (-). The first letter of an identifier cannot be a number.

To learn the full identifier specification, please visit the Unicode identifier syntax.

## Comments

Terraform supports three types of comments:
- `#` is a single-line comment. Everything after the `#` is ignored by Terraform.
- `//` is a single-line comment. Everything after the `//` is ignored by Terraform. By default, single-line comments use the hash sign (#). The automatic formatting tool will automatically replace // with #.
- `/* */` is a multi-line comment. Everything between `/*` and `*/` is ignored by Terraform.

## Encoding and Line Breaks

Terraform configuration files must always use UTF-8 encoding. Separators must use ASCII symbols, while other identifiers, comments, and string literals can use non-ASCII characters.

Terraform is compatible with both Unix-style and Windows-style line breaks, but Unix-style line breaks should ideally be used.