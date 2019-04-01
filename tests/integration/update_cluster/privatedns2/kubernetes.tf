locals = {
  bastion_autoscaling_group_ids     = ["${aws_autoscaling_group.bastion-privatedns2-example-com.id}"]
  bastion_security_group_ids        = ["${aws_security_group.bastion-privatedns2-example-com.id}"]
  bastions_role_arn                 = "${aws_iam_role.bastions-privatedns2-example-com.arn}"
  bastions_role_name                = "${aws_iam_role.bastions-privatedns2-example-com.name}"
  cluster_name                      = "privatedns2.example.com"
  master_autoscaling_group_ids      = ["${aws_autoscaling_group.master-us-test-1a-masters-privatedns2-example-com.id}"]
  master_security_group_ids         = ["${aws_security_group.masters-privatedns2-example-com.id}"]
  masters_role_arn                  = "${aws_iam_role.masters-privatedns2-example-com.arn}"
  masters_role_name                 = "${aws_iam_role.masters-privatedns2-example-com.name}"
  node_autoscaling_group_ids        = ["${aws_autoscaling_group.nodes-privatedns2-example-com.id}"]
  node_security_group_ids           = ["${aws_security_group.nodes-privatedns2-example-com.id}"]
  node_subnet_ids                   = ["${aws_subnet.us-test-1a-privatedns2-example-com.id}"]
  nodes_role_arn                    = "${aws_iam_role.nodes-privatedns2-example-com.arn}"
  nodes_role_name                   = "${aws_iam_role.nodes-privatedns2-example-com.name}"
  region                            = "us-test-1"
  route_table_private-us-test-1a_id = "${aws_route_table.private-us-test-1a-privatedns2-example-com.id}"
  route_table_public_id             = "${aws_route_table.privatedns2-example-com.id}"
  subnet_us-test-1a_id              = "${aws_subnet.us-test-1a-privatedns2-example-com.id}"
  subnet_utility-us-test-1a_id      = "${aws_subnet.utility-us-test-1a-privatedns2-example-com.id}"
  vpc_id                            = "vpc-12345678"
}

output "bastion_autoscaling_group_ids" {
  value = ["${aws_autoscaling_group.bastion-privatedns2-example-com.id}"]
}

output "bastion_security_group_ids" {
  value = ["${aws_security_group.bastion-privatedns2-example-com.id}"]
}

output "bastions_role_arn" {
  value = "${aws_iam_role.bastions-privatedns2-example-com.arn}"
}

output "bastions_role_name" {
  value = "${aws_iam_role.bastions-privatedns2-example-com.name}"
}

output "cluster_name" {
  value = "privatedns2.example.com"
}

output "master_autoscaling_group_ids" {
  value = ["${aws_autoscaling_group.master-us-test-1a-masters-privatedns2-example-com.id}"]
}

output "master_security_group_ids" {
  value = ["${aws_security_group.masters-privatedns2-example-com.id}"]
}

output "masters_role_arn" {
  value = "${aws_iam_role.masters-privatedns2-example-com.arn}"
}

output "masters_role_name" {
  value = "${aws_iam_role.masters-privatedns2-example-com.name}"
}

output "node_autoscaling_group_ids" {
  value = ["${aws_autoscaling_group.nodes-privatedns2-example-com.id}"]
}

output "node_security_group_ids" {
  value = ["${aws_security_group.nodes-privatedns2-example-com.id}"]
}

output "node_subnet_ids" {
  value = ["${aws_subnet.us-test-1a-privatedns2-example-com.id}"]
}

output "nodes_role_arn" {
  value = "${aws_iam_role.nodes-privatedns2-example-com.arn}"
}

output "nodes_role_name" {
  value = "${aws_iam_role.nodes-privatedns2-example-com.name}"
}

output "region" {
  value = "us-test-1"
}

output "route_table_private-us-test-1a_id" {
  value = "${aws_route_table.private-us-test-1a-privatedns2-example-com.id}"
}

output "route_table_public_id" {
  value = "${aws_route_table.privatedns2-example-com.id}"
}

output "subnet_us-test-1a_id" {
  value = "${aws_subnet.us-test-1a-privatedns2-example-com.id}"
}

output "subnet_utility-us-test-1a_id" {
  value = "${aws_subnet.utility-us-test-1a-privatedns2-example-com.id}"
}

output "vpc_id" {
  value = "vpc-12345678"
}

provider "aws" {
  region = "us-test-1"
}

resource "aws_autoscaling_attachment" "bastion-privatedns2-example-com" {
  elb                    = "${aws_elb.bastion-privatedns2-example-com.id}"
  autoscaling_group_name = "${aws_autoscaling_group.bastion-privatedns2-example-com.id}"
}

resource "aws_autoscaling_attachment" "master-us-test-1a-masters-privatedns2-example-com" {
  elb                    = "${aws_elb.api-privatedns2-example-com.id}"
  autoscaling_group_name = "${aws_autoscaling_group.master-us-test-1a-masters-privatedns2-example-com.id}"
}

resource "aws_autoscaling_group" "bastion-privatedns2-example-com" {
  name                 = "bastion.privatedns2.example.com"
  launch_configuration = "${aws_launch_configuration.bastion-privatedns2-example-com.id}"
  max_size             = 1
  min_size             = 1
  vpc_zone_identifier  = ["${aws_subnet.utility-us-test-1a-privatedns2-example-com.id}"]

  tag = {
    key                 = "KubernetesCluster"
    value               = "privatedns2.example.com"
    propagate_at_launch = true
  }

  tag = {
    key                 = "Name"
    value               = "bastion.privatedns2.example.com"
    propagate_at_launch = true
  }

  tag = {
    key                 = "k8s.io/role/bastion"
    value               = "1"
    propagate_at_launch = true
  }

  metrics_granularity = "1Minute"
  enabled_metrics     = ["GroupDesiredCapacity", "GroupInServiceInstances", "GroupMaxSize", "GroupMinSize", "GroupPendingInstances", "GroupStandbyInstances", "GroupTerminatingInstances", "GroupTotalInstances"]
}

resource "aws_autoscaling_group" "master-us-test-1a-masters-privatedns2-example-com" {
  name                 = "master-us-test-1a.masters.privatedns2.example.com"
  launch_configuration = "${aws_launch_configuration.master-us-test-1a-masters-privatedns2-example-com.id}"
  max_size             = 1
  min_size             = 1
  vpc_zone_identifier  = ["${aws_subnet.us-test-1a-privatedns2-example-com.id}"]

  tag = {
    key                 = "KubernetesCluster"
    value               = "privatedns2.example.com"
    propagate_at_launch = true
  }

  tag = {
    key                 = "Name"
    value               = "master-us-test-1a.masters.privatedns2.example.com"
    propagate_at_launch = true
  }

  tag = {
    key                 = "k8s.io/role/master"
    value               = "1"
    propagate_at_launch = true
  }

  metrics_granularity = "1Minute"
  enabled_metrics     = ["GroupDesiredCapacity", "GroupInServiceInstances", "GroupMaxSize", "GroupMinSize", "GroupPendingInstances", "GroupStandbyInstances", "GroupTerminatingInstances", "GroupTotalInstances"]
}

resource "aws_autoscaling_group" "nodes-privatedns2-example-com" {
  name                 = "nodes.privatedns2.example.com"
  launch_configuration = "${aws_launch_configuration.nodes-privatedns2-example-com.id}"
  max_size             = 2
  min_size             = 2
  vpc_zone_identifier  = ["${aws_subnet.us-test-1a-privatedns2-example-com.id}"]

  tag = {
    key                 = "KubernetesCluster"
    value               = "privatedns2.example.com"
    propagate_at_launch = true
  }

  tag = {
    key                 = "Name"
    value               = "nodes.privatedns2.example.com"
    propagate_at_launch = true
  }

  tag = {
    key                 = "k8s.io/role/node"
    value               = "1"
    propagate_at_launch = true
  }

  metrics_granularity = "1Minute"
  enabled_metrics     = ["GroupDesiredCapacity", "GroupInServiceInstances", "GroupMaxSize", "GroupMinSize", "GroupPendingInstances", "GroupStandbyInstances", "GroupTerminatingInstances", "GroupTotalInstances"]
}

resource "aws_ebs_volume" "us-test-1a-etcd-events-privatedns2-example-com" {
  availability_zone = "us-test-1a"
  size              = 20
  type              = "gp2"
  encrypted         = false

  tags = {
    KubernetesCluster                               = "privatedns2.example.com"
    Name                                            = "us-test-1a.etcd-events.privatedns2.example.com"
    "k8s.io/etcd/events"                            = "us-test-1a/us-test-1a"
    "k8s.io/role/master"                            = "1"
    "kubernetes.io/cluster/privatedns2.example.com" = "owned"
  }
}

resource "aws_ebs_volume" "us-test-1a-etcd-main-privatedns2-example-com" {
  availability_zone = "us-test-1a"
  size              = 20
  type              = "gp2"
  encrypted         = false

  tags = {
    KubernetesCluster                               = "privatedns2.example.com"
    Name                                            = "us-test-1a.etcd-main.privatedns2.example.com"
    "k8s.io/etcd/main"                              = "us-test-1a/us-test-1a"
    "k8s.io/role/master"                            = "1"
    "kubernetes.io/cluster/privatedns2.example.com" = "owned"
  }
}

resource "aws_eip" "us-test-1a-privatedns2-example-com" {
  vpc = true

  tags = {
    KubernetesCluster                               = "privatedns2.example.com"
    Name                                            = "us-test-1a.privatedns2.example.com"
    "kubernetes.io/cluster/privatedns2.example.com" = "owned"
  }
}

resource "aws_elb" "api-privatedns2-example-com" {
  name = "api-privatedns2-example-c-6jft30"

  listener = {
    instance_port     = 443
    instance_protocol = "TCP"
    lb_port           = 443
    lb_protocol       = "TCP"
  }

  security_groups = ["${aws_security_group.api-elb-privatedns2-example-com.id}"]
  subnets         = ["${aws_subnet.utility-us-test-1a-privatedns2-example-com.id}"]

  health_check = {
    target              = "SSL:443"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10
    timeout             = 5
  }

  idle_timeout = 300

  tags = {
    KubernetesCluster                               = "privatedns2.example.com"
    Name                                            = "api.privatedns2.example.com"
    "kubernetes.io/cluster/privatedns2.example.com" = "owned"
  }
}

resource "aws_elb" "bastion-privatedns2-example-com" {
  name = "bastion-privatedns2-examp-e704o2"

  listener = {
    instance_port     = 22
    instance_protocol = "TCP"
    lb_port           = 22
    lb_protocol       = "TCP"
  }

  security_groups = ["${aws_security_group.bastion-elb-privatedns2-example-com.id}"]
  subnets         = ["${aws_subnet.utility-us-test-1a-privatedns2-example-com.id}"]

  health_check = {
    target              = "TCP:22"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10
    timeout             = 5
  }

  idle_timeout = 300

  tags = {
    KubernetesCluster                               = "privatedns2.example.com"
    Name                                            = "bastion.privatedns2.example.com"
    "kubernetes.io/cluster/privatedns2.example.com" = "owned"
  }
}

resource "aws_iam_instance_profile" "bastions-privatedns2-example-com" {
  name = "bastions.privatedns2.example.com"
  role = "${aws_iam_role.bastions-privatedns2-example-com.name}"
}

resource "aws_iam_instance_profile" "masters-privatedns2-example-com" {
  name = "masters.privatedns2.example.com"
  role = "${aws_iam_role.masters-privatedns2-example-com.name}"
}

resource "aws_iam_instance_profile" "nodes-privatedns2-example-com" {
  name = "nodes.privatedns2.example.com"
  role = "${aws_iam_role.nodes-privatedns2-example-com.name}"
}

resource "aws_iam_role" "bastions-privatedns2-example-com" {
  name               = "bastions.privatedns2.example.com"
  assume_role_policy = "${file("${path.module}/data/aws_iam_role_bastions.privatedns2.example.com_policy")}"
}

resource "aws_iam_role" "masters-privatedns2-example-com" {
  name               = "masters.privatedns2.example.com"
  assume_role_policy = "${file("${path.module}/data/aws_iam_role_masters.privatedns2.example.com_policy")}"
}

resource "aws_iam_role" "nodes-privatedns2-example-com" {
  name               = "nodes.privatedns2.example.com"
  assume_role_policy = "${file("${path.module}/data/aws_iam_role_nodes.privatedns2.example.com_policy")}"
}

resource "aws_iam_role_policy" "bastions-privatedns2-example-com" {
  name   = "bastions.privatedns2.example.com"
  role   = "${aws_iam_role.bastions-privatedns2-example-com.name}"
  policy = "${file("${path.module}/data/aws_iam_role_policy_bastions.privatedns2.example.com_policy")}"
}

resource "aws_iam_role_policy" "masters-privatedns2-example-com" {
  name   = "masters.privatedns2.example.com"
  role   = "${aws_iam_role.masters-privatedns2-example-com.name}"
  policy = "${file("${path.module}/data/aws_iam_role_policy_masters.privatedns2.example.com_policy")}"
}

resource "aws_iam_role_policy" "nodes-privatedns2-example-com" {
  name   = "nodes.privatedns2.example.com"
  role   = "${aws_iam_role.nodes-privatedns2-example-com.name}"
  policy = "${file("${path.module}/data/aws_iam_role_policy_nodes.privatedns2.example.com_policy")}"
}

resource "aws_key_pair" "kubernetes-privatedns2-example-com-c4a6ed9aa889b9e2c39cd663eb9c7157" {
  key_name   = "kubernetes.privatedns2.example.com-c4:a6:ed:9a:a8:89:b9:e2:c3:9c:d6:63:eb:9c:71:57"
  public_key = "${file("${path.module}/data/aws_key_pair_kubernetes.privatedns2.example.com-c4a6ed9aa889b9e2c39cd663eb9c7157_public_key")}"
}

resource "aws_launch_configuration" "bastion-privatedns2-example-com" {
  name_prefix                 = "bastion.privatedns2.example.com-"
  image_id                    = "ami-12345678"
  instance_type               = "t2.micro"
  key_name                    = "${aws_key_pair.kubernetes-privatedns2-example-com-c4a6ed9aa889b9e2c39cd663eb9c7157.id}"
  iam_instance_profile        = "${aws_iam_instance_profile.bastions-privatedns2-example-com.id}"
  security_groups             = ["${aws_security_group.bastion-privatedns2-example-com.id}"]
  associate_public_ip_address = true

  root_block_device = {
    volume_type           = "gp2"
    volume_size           = 32
    delete_on_termination = true
  }

  lifecycle = {
    create_before_destroy = true
  }

  enable_monitoring = false
}

resource "aws_launch_configuration" "master-us-test-1a-masters-privatedns2-example-com" {
  name_prefix                 = "master-us-test-1a.masters.privatedns2.example.com-"
  image_id                    = "ami-12345678"
  instance_type               = "m3.medium"
  key_name                    = "${aws_key_pair.kubernetes-privatedns2-example-com-c4a6ed9aa889b9e2c39cd663eb9c7157.id}"
  iam_instance_profile        = "${aws_iam_instance_profile.masters-privatedns2-example-com.id}"
  security_groups             = ["${aws_security_group.masters-privatedns2-example-com.id}"]
  associate_public_ip_address = false
  user_data                   = "${file("${path.module}/data/aws_launch_configuration_master-us-test-1a.masters.privatedns2.example.com_user_data")}"

  root_block_device = {
    volume_type           = "gp2"
    volume_size           = 64
    delete_on_termination = true
  }

  ephemeral_block_device = {
    device_name  = "/dev/sdc"
    virtual_name = "ephemeral0"
  }

  lifecycle = {
    create_before_destroy = true
  }

  enable_monitoring = false
}

resource "aws_launch_configuration" "nodes-privatedns2-example-com" {
  name_prefix                 = "nodes.privatedns2.example.com-"
  image_id                    = "ami-12345678"
  instance_type               = "t2.medium"
  key_name                    = "${aws_key_pair.kubernetes-privatedns2-example-com-c4a6ed9aa889b9e2c39cd663eb9c7157.id}"
  iam_instance_profile        = "${aws_iam_instance_profile.nodes-privatedns2-example-com.id}"
  security_groups             = ["${aws_security_group.nodes-privatedns2-example-com.id}"]
  associate_public_ip_address = false
  user_data                   = "${file("${path.module}/data/aws_launch_configuration_nodes.privatedns2.example.com_user_data")}"

  root_block_device = {
    volume_type           = "gp2"
    volume_size           = 128
    delete_on_termination = true
  }

  lifecycle = {
    create_before_destroy = true
  }

  enable_monitoring = false
}

resource "aws_nat_gateway" "us-test-1a-privatedns2-example-com" {
  allocation_id = "${aws_eip.us-test-1a-privatedns2-example-com.id}"
  subnet_id     = "${aws_subnet.utility-us-test-1a-privatedns2-example-com.id}"

  tags = {
    KubernetesCluster                               = "privatedns2.example.com"
    Name                                            = "us-test-1a.privatedns2.example.com"
    "kubernetes.io/cluster/privatedns2.example.com" = "owned"
  }
}

resource "aws_route" "0-0-0-0--0" {
  route_table_id         = "${aws_route_table.privatedns2-example-com.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "igw-1"
}

resource "aws_route" "private-us-test-1a-0-0-0-0--0" {
  route_table_id         = "${aws_route_table.private-us-test-1a-privatedns2-example-com.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${aws_nat_gateway.us-test-1a-privatedns2-example-com.id}"
}

resource "aws_route53_record" "api-privatedns2-example-com" {
  name = "api.privatedns2.example.com"
  type = "A"

  alias = {
    name                   = "${aws_elb.api-privatedns2-example-com.dns_name}"
    zone_id                = "${aws_elb.api-privatedns2-example-com.zone_id}"
    evaluate_target_health = false
  }

  zone_id = "/hostedzone/Z3AFAKE1ZOMORE"
}

resource "aws_route_table" "private-us-test-1a-privatedns2-example-com" {
  vpc_id = "vpc-12345678"

  tags = {
    KubernetesCluster                               = "privatedns2.example.com"
    Name                                            = "private-us-test-1a.privatedns2.example.com"
    "kubernetes.io/cluster/privatedns2.example.com" = "owned"
    "kubernetes.io/kops/role"                       = "private-us-test-1a"
  }
}

resource "aws_route_table" "privatedns2-example-com" {
  vpc_id = "vpc-12345678"

  tags = {
    KubernetesCluster                               = "privatedns2.example.com"
    Name                                            = "privatedns2.example.com"
    "kubernetes.io/cluster/privatedns2.example.com" = "owned"
    "kubernetes.io/kops/role"                       = "public"
  }
}

resource "aws_route_table_association" "private-us-test-1a-privatedns2-example-com" {
  subnet_id      = "${aws_subnet.us-test-1a-privatedns2-example-com.id}"
  route_table_id = "${aws_route_table.private-us-test-1a-privatedns2-example-com.id}"
}

resource "aws_route_table_association" "utility-us-test-1a-privatedns2-example-com" {
  subnet_id      = "${aws_subnet.utility-us-test-1a-privatedns2-example-com.id}"
  route_table_id = "${aws_route_table.privatedns2-example-com.id}"
}

resource "aws_security_group" "api-elb-privatedns2-example-com" {
  name        = "api-elb.privatedns2.example.com"
  vpc_id      = "vpc-12345678"
  description = "Security group for api ELB"

  tags = {
    KubernetesCluster                               = "privatedns2.example.com"
    Name                                            = "api-elb.privatedns2.example.com"
    "kubernetes.io/cluster/privatedns2.example.com" = "owned"
  }
}

resource "aws_security_group" "bastion-elb-privatedns2-example-com" {
  name        = "bastion-elb.privatedns2.example.com"
  vpc_id      = "vpc-12345678"
  description = "Security group for bastion ELB"

  tags = {
    KubernetesCluster                               = "privatedns2.example.com"
    Name                                            = "bastion-elb.privatedns2.example.com"
    "kubernetes.io/cluster/privatedns2.example.com" = "owned"
  }
}

resource "aws_security_group" "bastion-privatedns2-example-com" {
  name        = "bastion.privatedns2.example.com"
  vpc_id      = "vpc-12345678"
  description = "Security group for bastion"

  tags = {
    KubernetesCluster                               = "privatedns2.example.com"
    Name                                            = "bastion.privatedns2.example.com"
    "kubernetes.io/cluster/privatedns2.example.com" = "owned"
  }
}

resource "aws_security_group" "masters-privatedns2-example-com" {
  name        = "masters.privatedns2.example.com"
  vpc_id      = "vpc-12345678"
  description = "Security group for masters"

  tags = {
    KubernetesCluster                               = "privatedns2.example.com"
    Name                                            = "masters.privatedns2.example.com"
    "kubernetes.io/cluster/privatedns2.example.com" = "owned"
  }
}

resource "aws_security_group" "nodes-privatedns2-example-com" {
  name        = "nodes.privatedns2.example.com"
  vpc_id      = "vpc-12345678"
  description = "Security group for nodes"

  tags = {
    KubernetesCluster                               = "privatedns2.example.com"
    Name                                            = "nodes.privatedns2.example.com"
    "kubernetes.io/cluster/privatedns2.example.com" = "owned"
  }
}

resource "aws_security_group_rule" "all-master-to-master" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.masters-privatedns2-example-com.id}"
  source_security_group_id = "${aws_security_group.masters-privatedns2-example-com.id}"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
}

resource "aws_security_group_rule" "all-master-to-node" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.nodes-privatedns2-example-com.id}"
  source_security_group_id = "${aws_security_group.masters-privatedns2-example-com.id}"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
}

resource "aws_security_group_rule" "all-node-to-node" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.nodes-privatedns2-example-com.id}"
  source_security_group_id = "${aws_security_group.nodes-privatedns2-example-com.id}"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
}

resource "aws_security_group_rule" "api-elb-egress" {
  type              = "egress"
  security_group_id = "${aws_security_group.api-elb-privatedns2-example-com.id}"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "bastion-egress" {
  type              = "egress"
  security_group_id = "${aws_security_group.bastion-privatedns2-example-com.id}"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "bastion-elb-egress" {
  type              = "egress"
  security_group_id = "${aws_security_group.bastion-elb-privatedns2-example-com.id}"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "bastion-to-master-ssh" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.masters-privatedns2-example-com.id}"
  source_security_group_id = "${aws_security_group.bastion-privatedns2-example-com.id}"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
}

resource "aws_security_group_rule" "bastion-to-node-ssh" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.nodes-privatedns2-example-com.id}"
  source_security_group_id = "${aws_security_group.bastion-privatedns2-example-com.id}"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
}

resource "aws_security_group_rule" "https-api-elb-0-0-0-0--0" {
  type              = "ingress"
  security_group_id = "${aws_security_group.api-elb-privatedns2-example-com.id}"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "https-elb-to-master" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.masters-privatedns2-example-com.id}"
  source_security_group_id = "${aws_security_group.api-elb-privatedns2-example-com.id}"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
}

resource "aws_security_group_rule" "icmp-pmtu-api-elb-0-0-0-0--0" {
  type              = "ingress"
  security_group_id = "${aws_security_group.api-elb-privatedns2-example-com.id}"
  from_port         = 3
  to_port           = 4
  protocol          = "icmp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "master-egress" {
  type              = "egress"
  security_group_id = "${aws_security_group.masters-privatedns2-example-com.id}"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "node-egress" {
  type              = "egress"
  security_group_id = "${aws_security_group.nodes-privatedns2-example-com.id}"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "node-to-master-tcp-1-2379" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.masters-privatedns2-example-com.id}"
  source_security_group_id = "${aws_security_group.nodes-privatedns2-example-com.id}"
  from_port                = 1
  to_port                  = 2379
  protocol                 = "tcp"
}

resource "aws_security_group_rule" "node-to-master-tcp-2382-4000" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.masters-privatedns2-example-com.id}"
  source_security_group_id = "${aws_security_group.nodes-privatedns2-example-com.id}"
  from_port                = 2382
  to_port                  = 4000
  protocol                 = "tcp"
}

resource "aws_security_group_rule" "node-to-master-tcp-4003-65535" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.masters-privatedns2-example-com.id}"
  source_security_group_id = "${aws_security_group.nodes-privatedns2-example-com.id}"
  from_port                = 4003
  to_port                  = 65535
  protocol                 = "tcp"
}

resource "aws_security_group_rule" "node-to-master-udp-1-65535" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.masters-privatedns2-example-com.id}"
  source_security_group_id = "${aws_security_group.nodes-privatedns2-example-com.id}"
  from_port                = 1
  to_port                  = 65535
  protocol                 = "udp"
}

resource "aws_security_group_rule" "ssh-elb-to-bastion" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.bastion-privatedns2-example-com.id}"
  source_security_group_id = "${aws_security_group.bastion-elb-privatedns2-example-com.id}"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
}

resource "aws_security_group_rule" "ssh-external-to-bastion-elb-0-0-0-0--0" {
  type              = "ingress"
  security_group_id = "${aws_security_group.bastion-elb-privatedns2-example-com.id}"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_subnet" "us-test-1a-privatedns2-example-com" {
  vpc_id            = "vpc-12345678"
  cidr_block        = "172.20.32.0/19"
  availability_zone = "us-test-1a"

  tags = {
    KubernetesCluster                               = "privatedns2.example.com"
    Name                                            = "us-test-1a.privatedns2.example.com"
    SubnetType                                      = "Private"
    "kubernetes.io/cluster/privatedns2.example.com" = "owned"
    "kubernetes.io/role/internal-elb"               = "1"
  }
}

resource "aws_subnet" "utility-us-test-1a-privatedns2-example-com" {
  vpc_id            = "vpc-12345678"
  cidr_block        = "172.20.4.0/22"
  availability_zone = "us-test-1a"

  tags = {
    KubernetesCluster                               = "privatedns2.example.com"
    Name                                            = "utility-us-test-1a.privatedns2.example.com"
    SubnetType                                      = "Utility"
    "kubernetes.io/cluster/privatedns2.example.com" = "owned"
    "kubernetes.io/role/elb"                        = "1"
  }
}

terraform = {
  required_version = ">= 0.9.3"
}
