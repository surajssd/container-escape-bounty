data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "aws_ami" "fedora" {
  most_recent = true

  filter {
    name   = "name"
    values = ["Fedora-Cloud-Base-29-*.x86_64-hvm-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["125523088429"]
}

resource "aws_key_pair" "ssh_public_key" {
  public_key = "${var.ssh_public_key}"
}

resource "aws_instance" "bountybox_apparmor" {
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "${var.instance_type}"
  key_name      = "${aws_key_pair.ssh_public_key.key_name}"

  vpc_security_group_ids = ["${aws_security_group.bountybox.id}"]
  subnet_id              = "${aws_subnet.bountybox.id}"

  tags = {
    Name = "${local.apparmor_instance_name}"
  }
}

resource "aws_instance" "bountybox_selinux" {
  ami           = "${data.aws_ami.fedora.id}"
  instance_type = "${var.instance_type}"
  key_name      = "${aws_key_pair.ssh_public_key.key_name}"

  vpc_security_group_ids = ["${aws_security_group.bountybox.id}"]
  subnet_id              = "${aws_subnet.bountybox.id}"

  tags = {
    Name = "${local.selinux_instance_name}"
  }
}

resource "aws_security_group" "bountybox" {
  name_prefix = "bountybox_sg"
  vpc_id      = "${aws_vpc.bountybox.id}"
}

# Ingress rules to allow traffic for ssh, http, and https.
resource "aws_security_group_rule" "allow_ssh" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.bountybox.id}"
}

resource "aws_security_group_rule" "allow_http" {
  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.bountybox.id}"
}

resource "aws_security_group_rule" "allow_https" {
  type        = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.bountybox.id}"
}

resource "aws_security_group_rule" "allow_custom_container" {
  type        = "ingress"
  from_port   = 36100
  to_port     = 36110
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.bountybox.id}"
}

resource "aws_security_group_rule" "allow_egress" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.bountybox.id}"
}

resource "aws_route53_record" "bountybox_apparmor" {
  zone_id = "${var.dns_zone_id}"
  name    = "${local.domain_apparmor}"
  type    = "A"
  ttl     = "300"

  records = ["${aws_eip.ip_bountybox_apparmor.public_ip}"]
}

resource "aws_route53_record" "bountybox_selinux" {
  zone_id = "${var.dns_zone_id}"
  name    = "${local.domain_selinux}"
  type    = "A"
  ttl     = "300"

  records = ["${aws_eip.ip_bountybox_selinux.public_ip}"]
}
