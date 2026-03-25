resource "aws_iam_user" "test" {
  count = length(var.users)

  name = var.users[count.index]
}