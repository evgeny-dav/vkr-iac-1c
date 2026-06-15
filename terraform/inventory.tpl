[db_server]
${db_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/yc_key ansible_host=${db_ip}

[1c_server]
${app_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/yc_key ansible_host=${app_ip}
%{ for ip in worker_ips ~}
${ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/yc_key ansible_host=${ip}
%{ endfor ~}

[all:vars]
ansible_python_interpreter=/usr/bin/python3
