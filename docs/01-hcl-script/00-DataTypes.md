# Data Types

| | |
| --- | --- |
| **Status** | Pending Approval |
| **Author** | [Yi-Ting Li](yiting-tom.github.io) |
| **Version** | 1.0.0 |
| **Last Updated** | 2023-03-21 |
| **Created At** | 2023-03-21 |

## Table of Contents

* [Data Types](#data-types)
   * [Non-structured data types](#non-structured-data-types)
      * [Implicit Conversion](#implicit-conversion)
   * [Structured data types](#structured-data-types)
      * [Type Abbreviations](#type-abbreviations)
      * [Type Abbreviations in object Type](#type-abbreviations-in-object-type)
         * [Example: Embedded structure with optional attributes and default values](#example-embedded-structure-with-optional-attributes-and-default-values)
         * [Example: Conditionally Setting a Default Property](#example-conditionally-setting-a-default-property)
   * [Type Constraint any](#type-constraint-any)
   * [Non-type Constraint null](#non-type-constraint-null)

<hr>

## Non-structured data types

1. `string`: It can be used to store text data such as names, addresses, or other alphanumeric values.
2. `number`: It can be used to store integer or floating-point values, such as age, height, weight, or temperature.
3. `bool`: It can be used to store binary values, such as whether a certain condition is met or not.

### Implicit Conversion

`number` and `bool` can be converted to `string` implicitly, and vice versa. For example, a `string` value with "true" will be converted to true in `bool` format. Similarly, "3.1415926" can be converted to 3.1415926 in `number` format.

## Structured data types

1. `list`: This data type represents an ordered collection of elements of the same data type. It can be used to store a sequence of values, such as a list of names or a list of numbers.

2. `map`: This data type represents an unordered collection of key-value pairs, where each key is unique. It can be used to store data that can be accessed by a specific key, such as a dictionary or a configuration file. **the key will be `string` type**.

3. `set`: This data type represents an unordered collection of unique elements of the same data type. It can be used to store a collection of unique values, such as a set of keywords or a set of user IDs.

4. `object`: a type of conforming type composed of attributes with names and types. Its schema information is described in the form of `{ <KEY>=<TYPE>, <KEY>=<TYPE>,...}`. For example, `object({age=number, name=string})` represents an object consisting of two attributes named "age" with a type of number and "name" with a type of string. A valid value assigned to the object type must have all attribute values, but _may have additional attributes (which will be discarded upon assignment)_. For example, `{ age=18 }` is an **invalid** value for `object({age=number,name=string})`, but `{ age=18, name="john", gender="male" }` is a **valid** value, but gender will be discarded upon assignment.

5. `tuple`: Similar to list, a `tuple` is a contiguous collection of values, but each element has an **independent** type. The schema of a `tuple` is described in the form of `[\<TYPE\>, \<TYPE\>, ...]`. The number of elements in the tuple must be **equal** to the number of types declared in the schema, and each element's type must be the same as the corresponding position in the tuple schema. e.g., a valid asignment of type `tuple([string, number, bool])` can be `["a", 15, true]`

### Type Abbreviations

Terraform supports type abbreviation, where `list` is equivalent to `list(any)`, `map` is equivalent to `map(any)`, and `set` is equivalent to `set(any)`. The `any` type represents any element type, as long as all elements are of the same type. For example, assigning `list(number)` to `list(any)` or `list(string)` to `list(any)` is legal. However, all elements within a list must be of the same type.

### Type Abbreviations in `object` Type

- `object` and `map`: If a map's set of keys contains all of the attributes specified by an object, the map can be converted to an `object`. Any extra key-value pairs in the map will be discarded. The conversion of `map` -> `object` -> `map` may result in data loss.
- `tuple` and `list`: When the number of elements in a list is exactly the length declared by a `tuple`, the `list` can be converted to a `tuple`. For example, a list with values `["18", "true", "john"]` can be converted to a `tuple([number, bool, string])`, resulting in `[18, true, "john"]`.
- `set` and `tuple`: When a `list` or `tuple` is converted to a `set`, duplicate values will be discarded, and the original order of the values will be lost. If a `set` is converted to a `list` or `tuple`, the elements will be sorted in the following order: if the elements of the set are strings, they will be sorted in **lexicographic order**; for other types of elements, **no specific** order is guaranteed.

Of course, if the types do not match, Terraform will report an error. For example, if we try to convert `object({name = ["Kristy", "Claudia", "Mary Anne", "Stacey"], age = 12})` to the `map(string)` type, this is not valid because the value of name is a `list`, which cannot be converted to a `string`.

### `optional` Attribute in `object` Type

Since Terraform 1.3, we can use the `optional` modifier to declare optional attributes in an `object` type definition.
We can use the optional modifier to declare an attribute as optional. For example:

```terraform
variable "with_optional_attribute" {
type = object({
    a = string                # a required attribute
    b = optional(string)      # an optional attribute
    c = optional(number, 127) # an optional attribute with default value
})
}
```

Here we declared b as optional. If the passed object doesn't have b, Terraform will use null as its value. We also declared c as optional, with 127 as its default value. If the passed object doesn't have c, Terraform will use 127 as its value.
The optional modifier has two parameters:

- Type: (Required) The first parameter indicates the type of the attribute.
- Default value: (Optional) The second parameter specifies the default value to use if the attribute isn't defined in the object. The default value must be compatible with the type parameter. If no default value is specified, Terraform will use null as the default value.

An optional attribute with a non-null default value ensures that the attribute won't be read as null within the module. When the user hasn't set the attribute or has explicitly set it to null, Terraform will use the default value, so the module doesn't need to check whether the attribute is null

Terraform sets default values for objects from top to bottom, which means that it applies the default value specified by the optional modifier first, and then sets default values for any nested objects.

Example: Embedded structure with optional attributes and default values
The following example demonstrates an input variable used to describe a storage bucket that stores the content of a static website. The type of the variable includes a series of optional attributes, including "website", which is not only optional itself, but also contains several optional attributes and default values.

#### Example: Embedded structure with optional attributes and default values

The following example demonstrates an input variable used to describe a storage bucket that stores the content of a static website. The type of the variable includes a series of optional attributes, including `website`, which is not only optional itself, but also contains several optional attributes and default values.

```terraform
variable "buckets" {
    type = list(object({
        name = string
        enabled = optional(bool, true)
        website = optional(object({
            index_document = optional(string, "index.html")
            error_document = optional(string, "error.html")
            routing_rules = optional(string)
        }), {})
    }))
}
```

The following is an example `terraform.tfvars` file that defines three storage buckets for `var.buckets`:

- **Production** is configured with a redirect `routing rule`
- **Archived** uses the default configuration but is disabled
- **Docs** replaces index and error pages with text files

The **production** bucket doesn't specify an index or error page, and the archived bucket completely ignores the `website` configuration. Terraform uses the default values specified in the bucket type constraint.

```terraform
buckets = [
  {
    name = "production"
    website = {
      routing_rules = <<-EOT
      [
        {
          "Condition" = { "KeyPrefixEquals": "img/" },
          "Redirect"  = { "ReplaceKeyPrefixWith": "images/" }
        }
      ]
      EOT
    }
  }, {
    name = "archived"
    enabled = false
  }, {
    name = "docs"
    website = {
      index_document = "index.txt"
      error_document = "error.txt"
    }
  },
]
```

- For the **production** and **docs** buckets, Terraform sets enabled to `true`. Terraform also configures website with default values and then overrides them with the values specified in the **docs** bucket.
- For the **archived** and **docs** buckets, Terraform sets `routing_rules` to `null`. When Terraform doesn't read an optional attribute and the attribute has no default value set, Terraform sets the attribute to `null`.
- For the **archived** bucket, Terraform sets the website attribute to the default value defined in the buckets type constraint.

Here is the output when using tolist:

```terraform
[
  {
    "enabled" = true
    "name" = "production"
    "website" = {
      "error_document" = "error.html"
      "index_document" = "index.html"
      "routing_rules" = <<-EOT
      [
        {
          "Condition" = { "KeyPrefixEquals": "img/" },
          "Redirect"  = { "ReplaceKeyPrefixWith": "images/" }
        }
      ]

      EOT
    }
  },
  {
    "enabled" = false
    "name" = "archived"
    "website" = {
      "error_document" = "error.html"
      "index_document" = "index.html"
      "routing_rules" = tostring(null)
    }
  },
  {
    "enabled" = true
    "name" = "docs"
    "website" = {
      "error_document" = "error.txt"
      "index_document" = "index.txt"
      "routing_rules" = tostring(null)
    }
  },
]
```

#### Example: Conditionally Setting a Default Property

Sometimes we need to dynamically decide whether to set a value for an optional parameter based on the value of other data. In this scenario, the calling module can use a conditional expression with null to dynamically decide whether to set the parameter.

In the example below, we use the variable `buckets` from the previous example. We use the following example to conditionally override the `index_document` and `error_document` settings in the `website` object based on the value of the new input variable `var.legacy_filenames`:

```terraform
variable "legacy_filenames" {
  type     = bool
  default  = false
  nullable = false
}

module "buckets" {
  source = "./modules/buckets"

  buckets = [
    {
      name = "maybe_legacy"
      website = {
        error_document = var.legacy_filenames ? "ERROR.HTM" : null
        index_document = var.legacy_filenames ? "INDEX.HTM" : null
      }
    },
  ]
}
```

When `var.legacy_filenames` is set to `true`, the call overrides the file names for `error_document` and `index_document`. When its value is `false`, the call doesn't specify these two file names, so the module uses the default values defined.

## Type Constraint `any`

`any` is a type constraint in Terraform. It is not a type itself, but a placeholder. Whenever a value is assigned to a complex type constrained by `any`, Terraform tries to calculate the most accurate type to replace `any`.

For example, if we assign `["a", "b", "c"]` to `list(any)`, its physical type in Terraform is first compiled into `tuple([string, string, string])`. Then Terraform considers tuples and lists to be similar, so it tries to convert it to `list(string)`. Since `list(string)` satisfies the constraint of `list(any)`, Terraform replaces `any` with `string`, and the final type after assignment is `list(string)`.

Since all elements in `list(any)` must have the same type, some type conversions will implicitly convert the elements to the same type when converting to `list(any)`. For example, when we assign `["a", 1, "b"]` to `list(any)`, Terraform finds that `1` can be converted to `"1"`, so the final value is `["a", "1", "b"]`, and the final type is `list(string)`. Similarly, if we want to convert `["a", [], "b"]` to `list(any)`, Terraform cannot find a suitable target type for all elements to be successfully implicitly converted, so Terraform reports an error, requiring all elements to be of the same type.

If you do not want any constraints when declaring a type, you can use `any`:

```terraform=
variable "no_type_constraint" {
  type = any
}
```

This way, Terraform can assign any type of data to it.

## Non-type Constraint `null`

It represents missing data. If a parameter is set to `null`, Terraform assumes that you forgot to assign a value to it. If the parameter has a default value, Terraform will use it. However, if there's no default value and the parameter is required, Terraform will throw an error.

`null` is very useful in conditional expressions. You can skip assigning a value to a parameter if a certain condition isn't met. e.g., Terraform version before 1.3 is not support `optional` modifier in `object` data type, but we can assign `null` to these attributes, i.e., declaring my_object variable type as `object`, with attribute a with type `string`, b with type `number`, and c with type `bool`.

```terraform
variable "my_object" {
  type = object({
    a = string
    b = number
    c = bool
  })
}
```

If we only want to assign attribute a to `string` "a", but we have also assign attributes b and c too or Terraform will raise an error. To over come this, we can assign `null` to b and c.

```terraform
{
  a = "a"
  b = null
  c = null
}
```
