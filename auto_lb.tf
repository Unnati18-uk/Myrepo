resource "aws_launch_template" "home_template" {
  name          = "${var.name}-home-launch-template"
  image_id      = var.image_id
  instance_type = var.instance_type
  key_name      = var.key_name

  network_interfaces {
    associate_public_ip_address = true
    subnet_id                   = aws_subnet.public_sub_a.id
    security_groups             = [aws_security_group.my_sg.id]
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    apt update -y
    apt install -y nginx
    echo "<h1>Welcome to Homepage</h1>" > /var/www/html/index.html
    systemctl start nginx
    systemctl enable nginx
  EOF
  )

  tags = {
    Name = "${var.name}-home-launch-template"
  }
}

resource "aws_launch_template" "laptop_template" {
  name          = "${var.name}-laptop-launch-template"
  image_id      = var.image_id
  instance_type = var.instance_type
  key_name      = var.key_name

  network_interfaces {
    associate_public_ip_address = true
    subnet_id                   = aws_subnet.public_sub_a.id
    security_groups             = [aws_security_group.my_sg.id]
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    apt update -y
    apt install -y nginx
    mkdir -p /var/www/html/laptop
    echo "<h1>Welcome to Laptop Page</h1>" > /var/www/html/laptop/index.html
    systemctl start nginx
    systemctl enable nginx
  EOF
  )

  tags = {
    Name = "${var.name}-laptop-launch-template"
  }
}

resource "aws_launch_template" "mobile_template" {
  name          = "${var.name}-mobile-launch-template"
  image_id      = var.image_id
  instance_type = var.instance_type
  key_name      = var.key_name

  network_interfaces {
    associate_public_ip_address = true
    subnet_id                   = aws_subnet.public_sub_a.id
    security_groups             = [aws_security_group.my_sg.id]
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    apt update -y
    apt install -y nginx
    mkdir -p /var/www/html/mobile
    echo "<h1>Welcome to Mobile Page</h1>" > /var/www/html/mobile/index.html
    systemctl start nginx
    systemctl enable nginx
  EOF
  )

  tags = {
    Name = "${var.name}-mobile-launch-template"
  }
}

resource "aws_autoscaling_group" "home_asg" {
  desired_capacity       = 3
  max_size               = 5
  min_size               = 2
  vpc_zone_identifier    = [aws_subnet.public_sub_a.id, aws_subnet.public_sub_b.id]

  launch_template {
    id      = aws_launch_template.home_template.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.home_target_group.arn]

  health_check_type         = "ELB"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "${var.name}-home-asg-instance"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_group" "laptop_asg" {
  desired_capacity       = 3
  max_size               = 5
  min_size               = 2
  vpc_zone_identifier    = [aws_subnet.public_sub_a.id, aws_subnet.public_sub_b.id]

  launch_template {
    id      = aws_launch_template.laptop_template.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.laptop_target_group.arn]

  health_check_type         = "ELB"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "${var.name}-laptop-asg-instance"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_group" "mobile_asg" {
  desired_capacity       = 3
  max_size               = 5
  min_size               = 2
  vpc_zone_identifier    = [aws_subnet.public_sub_a.id, aws_subnet.public_sub_b.id]

  launch_template {
    id      = aws_launch_template.mobile_template.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.mobile_target_group.arn]

  health_check_type         = "ELB"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "${var.name}-mobile-asg-instance"
    propagate_at_launch = true
  }
}

resource "aws_lb_target_group" "home_target_group" {
  name     = "${var.name}-home-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id
}

resource "aws_lb_target_group" "laptop_target_group" {
  name     = "${var.name}-laptop-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id
}

resource "aws_lb_target_group" "mobile_target_group" {
  name     = "${var.name}-mobile-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id
}

resource "aws_lb" "my_alb" {
  name               = "${var.name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.my_sg.id]
  subnets            = [aws_subnet.public_sub_a.id, aws_subnet.public_sub_b.id]

  enable_deletion_protection = false

  tags = {
    Name = "${var.name}-alb"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.my_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      status_code = 200
      content_type = "text/plain"
      message_body = "Welcome to Homepage"
    }
  }
}

resource "aws_lb_listener_rule" "laptop" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.laptop_target_group.arn
  }

  condition {
    path_pattern {
      values = ["/laptop/*"]
  }
}
}

resource "aws_lb_listener_rule" "mobile" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 2

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.mobile_target_group.arn
  }

  condition {
    path_pattern {
      values = ["/mobile/*"]
}
  }
}
