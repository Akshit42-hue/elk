terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}



data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_key_pair" "TF_key1" {
    key_name = "TF_key1"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC2MUcMXzvr5h5vSVUA3vLg4DMqklPG2pu29BU368E+aPtSQYxCE7Ftg7ZK9ZsWdhJwDaJ0XKxclIMCyDTODam9FP3PeeL+EQElo6G8rExqh5/BkJEGQgQmrxHJIGh34uqYghx6Yf/yEK/K+OU6OBaja4ypXrXrsn2liaYAn7JfhFHT+uPWgD9dixXxuYLDVDVZ/jgFQxpt0A6czaGVcRnI/WxXMWqCC6fifF48qiACXRhdP+GC/KQiuBrZEAc352DOLnvltCG5eAmQUOBn1BJqOOqmTGjTlh9WSl5d5kxqZKVlZqSZrnblq0swNRjO9iVBteqIGLmcPAmUxaBgNkLGlQvKj7T8pWT2lqQZOuh+8+LMb2vcXD0j+6dbj2Y4vBAI04g3eVxeRsDasp3X3y8PVTew54TuJMPdc4EZTpRi7+2GHrs6t8PI6B/LP2SfuSSWgPo6ryfAAm4DkLCw4huS1EewNg3xGCkx7QBGcJlDzYvYxS6j40ZEC27DWrEmV18= dell@DESKTOP-IB85O0E"
}

resource "aws_instance" "ec2_instance" {
  ami           = data.aws_ami.ubuntu.id  # Specify the AMI for Ubuntu
  instance_type = "t3.small"  # based on your preference

  tags = {
    Name = "ELK-Nginx-Instance"
  }

  key_name      = "TF_key1"  # Specify your SSH key pair name

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install nginx -y
              sudo apt-get update
              sudo apt-get install -y openjdk-8-jdk
              wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
              sudo sh -c 'echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" > /etc/apt/sources.list.d/elastic-7.x.list'
              sudo apt-get update
              sudo apt-get install -y elasticsearch kibana logstash
              sudo systemctl start elasticsearch
              sudo systemctl enable elasticsearch
              sudo systemctl start kibana
              sudo systemctl enable kibana
              sudo systemctl restart kibana
              sudo systemctl start logstash
              sudo systemctl enable logstash
              sudo apt-get install -y filebeat
              sudo systemctl start filebeat
              sudo systemctl enable filebeat
              sudo sh -c 'echo "filebeat.modules:
              - module: nginx
                access:
                  enabled: true
                  var.paths: [\"/var/log/nginx/access.log\"]' > /etc/filebeat/filebeat.yml'

              sudo systemctl restart filebeat
              EOF              
}


