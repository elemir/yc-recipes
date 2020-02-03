variable "token" {
    type = string
}

variable "cloud_id" {
    type = string
}

variable "folder_id" {
    type = string
}

provider "yandex" {
  token     = "${var.token}"
  cloud_id  = "${var.cloud_id}"
  folder_id = "${var.folder_id}"
}

resource "yandex_vpc_network" "elk-net" {
  name = "elk-net"
}

resource "yandex_vpc_subnet" "elk-subnet-a" {
  name = "elk-subnet-a"
  zone = "ru-central1-a"
  network_id = "${yandex_vpc_network.elk-net.id}"
  v4_cidr_blocks = ["192.168.0.0/24"]
}

resource "yandex_vpc_subnet" "elk-subnet-b" {
  name = "elk-subnet-b"
  zone = "ru-central1-b"
  network_id = "${yandex_vpc_network.elk-net.id}"
  v4_cidr_blocks = ["192.168.1.0/24"]
}

resource "yandex_vpc_subnet" "elk-subnet-c" {
  name = "elk-subnet-c"
  zone = "ru-central1-c"
  network_id = "${yandex_vpc_network.elk-net.id}"
  v4_cidr_blocks = ["192.168.2.0/24"]
}

resource "yandex_iam_service_account" "elk-sa" {
  name = "elk-sa"
  description = "service account for k8s cluster"
}

resource "yandex_resourcemanager_folder_iam_member" "elk-k8s-editor" {
  folder_id = "${var.folder_id}"

  role   = "admin"
  member = "serviceAccount:${yandex_iam_service_account.elk-sa.id}"
}

resource "yandex_kubernetes_cluster" "elk-k8s-cluster" {
  name        = "elk-k8s-cluster"
  description = "k8s cluster for ELK"

  network_id = "${yandex_vpc_network.elk-net.id}"

  master {
    regional {
      region = "ru-central1"

      location {
        zone      = "${yandex_vpc_subnet.elk-subnet-a.zone}"
        subnet_id = "${yandex_vpc_subnet.elk-subnet-a.id}"
      }

      location {
        zone      = "${yandex_vpc_subnet.elk-subnet-b.zone}"
        subnet_id = "${yandex_vpc_subnet.elk-subnet-b.id}"
      }

      location {
        zone      = "${yandex_vpc_subnet.elk-subnet-c.zone}"
        subnet_id = "${yandex_vpc_subnet.elk-subnet-c.id}"
      }
    }

    public_ip = true
  }

  service_account_id      = "${yandex_iam_service_account.elk-sa.id}"
  node_service_account_id = "${yandex_iam_service_account.elk-sa.id}"

  release_channel = "STABLE"

  depends_on = [
    yandex_resourcemanager_folder_iam_member.elk-k8s-editor,
  ]

  timeouts {
    create = "15m"
  }
}

resource "yandex_kubernetes_node_group" "elk-nodes" {
  cluster_id  = "${yandex_kubernetes_cluster.elk-k8s-cluster.id}"
  name        = "elk-nodes"
  description = "nodes for elk cluster"

  instance_template {
    platform_id = "standard-v2"
    nat = true
    
    resources {
      memory = 6
      cores  = 2
    }

    boot_disk {
      type = "network-hdd"
      size = "64"
    }

    scheduling_policy {
      preemptible = false
    }
  }

  scale_policy {
    fixed_scale {
      size = 3
    }
  }

  allocation_policy {
    location {
      zone = "ru-central1-a"
    }
    location {
      zone = "ru-central1-b"
    }
    location {
      zone = "ru-central1-c"
    }
  }
}
