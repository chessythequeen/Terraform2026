
resource "aws_iam_user" "map_example" {
  for_each = var.users_map

  name = each.key

  tags = {
    environment = each.value
  }
}

# Output: Transform names + environment
output "users_with_environment" {
  value = [
    for username, user in aws_iam_user.map_example:
    "${username} works in ${user.tags["environment"]}"
  ]
}