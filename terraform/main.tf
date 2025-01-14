provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "elb_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Elastic_BeanStalk_VPC"
  }
}

resource "aws_subnet" "elb_subnet" {
  vpc_id                  = aws_vpc.elb_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Elastic Beanstalk"
  }
}

resource "aws_internet_gateway" "server_to_internet" {
  vpc_id = aws_vpc.elb_vpc.id
  tags = {
    Name = "elastic_beanstalk_to_Internet"
  }
}

resource "aws_route_table" "jenkins_route_table" {
  vpc_id = aws_vpc.elb_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.server_to_internet.id
  }
  tags = {
    Name = "elastic-bean-stalk-route-table"
  }
}

resource "aws_route_table_association" "route_table_accociation" {
  subnet_id      = aws_subnet.elb_subnet.id
  route_table_id = aws_route_table.jenkins_route_table.id
}

resource "aws_security_group" "allow_all" {
  name   = "Codebuild-sg"
  vpc_id = aws_vpc.elb_vpc.id

  ingress {
    description = "Allow all traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# codebuild role

resource "aws_iam_role" "this" {
  name = "codebuild_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "this" {
  statement {
    sid = ""
    actions = [
      "logs:*",
      "s3:*",
      "codebuild:*",
      "secretsmanager:*",
      "iam:*",
    ]
    resources = ["*"]
    effect    = "Allow"
  }

}

resource "aws_iam_policy" "this" {
  name        = "code_pipeline_policy"
  path        = "/"
  description = "Codebuild policy"
  policy      = data.aws_iam_policy_document.this.json
}

resource "aws_iam_role_policy_attachment" "attachment1" {
  policy_arn = aws_iam_policy.this.arn
  role       = aws_iam_role.this.id
}

resource "aws_iam_role_policy_attachment" "attachment2" {
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
  role       = aws_iam_role.this.id
}