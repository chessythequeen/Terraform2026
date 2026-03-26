
resource "aws_launch_template" "app" {
  image_id      = "ami-02dfbd4ff395f2a1b"
  instance_type = local.instance_type
}

resource "aws_autoscaling_group" "app_asg" {
  min_size         = local.min_size
  max_size         = local.max_size
  desired_capacity = local.min_size

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

}