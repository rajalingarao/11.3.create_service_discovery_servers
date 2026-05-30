resource "aws_instance" "sd_ec2" {
    for_each = var.instances
    ami           = data.aws_ami.rhel_info.id
    instance_type = each.value
    vpc_security_group_ids = [var.allow_everything]
    root_block_device {
        volume_type           = "gp3"
        volume_size           = 50
        delete_on_termination = true
    }
    user_data = file("${path.module}/install_service_discover.sh")
    # iam_instance_profile        = aws_iam_instance_profile.prometheus_instance_profile.name
    
    # user_data = <<-EOF
    #         #!/bin/bash
    #         cd /opt
    #         wget https://github.com/prometheus/node_exporter/releases/download/v1.9.1/node_exporter-1.9.1.linux-amd64.tar.gz
    #         tar -xf node_exporter-1.9.1.linux-amd64.tar.gz
    #         mv node_exporter-1.9.1.linux-amd64 node_exporter
            
    #         echo "
    #         [Unit]
    #         Description=Node Exporter
    #         After=network-online.target

    #         [Service]
    #         Restart=on-failure
    #         ExecStart=/opt/node_exporter/node_exporter

    #         [Install]
    #         WantedBy=multi-user.target
    #         " > /etc/systemd/system/node_exporter.service

    #         systemctl daemon-reload
    #         systemctl enable node_exporter
    #         systemctl start node_exporter
    #         systemctl status node_exporter
    #           EOF

    tags = {
        Name = each.key
        Monitoring = "true"
    }
}
resource "aws_route53_record" "sd_r53" {
    for_each = aws_instance.sd_ec2
    zone_id = var.zone_id
    name    = "${each.key}.${var.domain_name}"
    type    = "A"
    ttl     = 1
    records = each.key == "" ? [] : [each.value.public_ip]
    allow_overwrite = true
}