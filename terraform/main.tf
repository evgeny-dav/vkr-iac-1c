terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
    local = {
      source = "hashicorp/local"
    }
  }
}

provider "yandex" {
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = "ru-central1-a"
  service_account_key_file = pathexpand("~/.yc/vkr-key.json")
}

resource "yandex_vpc_network" "network_1c" {
  name = "iac-1c-network"
}

resource "yandex_vpc_subnet" "subnet_1c" {
  name           = "iac-1c-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network_1c.id
  v4_cidr_blocks = ["10.10.0.0/24"]
}

# Сервер базы данных
resource "yandex_compute_instance" "db_server" {
  name        = "iac-1c-db-server"
  platform_id = "standard-v3"

  resources {
    cores         = 2
    memory        = 4
    core_fraction = 100
  }

  boot_disk {
    initialize_params {
      image_id = "fd8emvfmfoaordspe1jr"
      size     = 30
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet_1c.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file(pathexpand(var.ssh_public_key))}"
  }
}

# Сервер 1С (основной)
resource "yandex_compute_instance" "server_1c" {
  name        = "iac-1c-app-server"
  platform_id = "standard-v3"

  resources {
    cores         = 4
    memory        = 8
    core_fraction = 100
  }

  boot_disk {
    initialize_params {
      image_id = "fd8emvfmfoaordspe1jr"
      size     = 30
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet_1c.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file(pathexpand(var.ssh_public_key))}"
  }
}

# Дополнительные рабочие серверы 1С
resource "yandex_compute_instance" "server_1c_worker" {
  count       = 0
  name        = "iac-1c-worker-${count.index}"
  platform_id = "standard-v3"

  resources {
    cores         = 4
    memory        = 8
    core_fraction = 100
  }

  boot_disk {
    initialize_params {
      image_id = "fd8emvfmfoaordspe1jr"
      size     = 30
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet_1c.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file(pathexpand(var.ssh_public_key))}"
  }
}

output "db_server_ip" {
  value = yandex_compute_instance.db_server.network_interface[0].nat_ip_address
}

output "server_1c_ip" {
  value = yandex_compute_instance.server_1c.network_interface[0].nat_ip_address
}

output "worker_ips" {
  value = yandex_compute_instance.server_1c_worker[*].network_interface[0].nat_ip_address
}

resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tpl", {
    db_ip      = yandex_compute_instance.db_server.network_interface[0].nat_ip_address
    app_ip     = yandex_compute_instance.server_1c.network_interface[0].nat_ip_address
    worker_ips = yandex_compute_instance.server_1c_worker[*].network_interface[0].nat_ip_address
  })
  filename = "../ansible/inventory.ini"
}
