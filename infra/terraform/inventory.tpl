[jenkins]
jenkins-server ansible_host=${instance_ip} ansible_user=ec2-user ansible_private_key_file=/Users/yasinsaleem/CourseWork/DevOps/vle7/yasinkey.pem

[jenkins:vars]
# Common variables for all jenkins hosts
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
ansible_python_interpreter=/usr/bin/python3
ansible_pkg_mgr=yum
aws_region=${aws_region}
project_name=${project_name}