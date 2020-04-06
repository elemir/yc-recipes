locals {
  net_cidr = ["10.0.0.0/16"]
  web_cidr = ["10.1.0.0/16", "10.2.0.0/16"]
}

data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-1804-lts"
}

resource "yandex_vpc_network" "net" {
  name = "net"
}

resource "yandex_vpc_subnet" "subnet" {
  count = length(local.net_cidr)

  v4_cidr_blocks = [local.net_cidr[count.index]]
  zone           = "ru-central1-b"
  network_id     = "${yandex_vpc_network.net.id}"
  route_table_id = "${yandex_vpc_route_table.net-route.id}"
}

resource "yandex_vpc_route_table" "net-route" {
  network_id = "${yandex_vpc_network.net.id}"

  dynamic "static_route" {
    for_each = local.web_cidr

    content {
      destination_prefix = static_route.value
      next_hop_address   = "${module.router.address[0]}"
    }
  }
}

resource "yandex_compute_instance" "net-instance" {
  name        = "net-instance"
  platform_id = "standard-v2"
  zone        = "ru-central1-b"

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = "${data.yandex_compute_image.ubuntu.id}"
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.subnet[0].id}"
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

resource "yandex_vpc_network" "web" {
  name = "web"
}

resource "yandex_vpc_subnet" "subweb" {
  count = length(local.web_cidr)

  v4_cidr_blocks = [local.web_cidr[count.index]]
  zone           = "ru-central1-c"
  network_id     = "${yandex_vpc_network.web.id}"
  route_table_id = "${yandex_vpc_route_table.web-route.id}"
}

resource "yandex_vpc_route_table" "web-route" {
  network_id = "${yandex_vpc_network.web.id}"

  dynamic "static_route" {
    for_each = local.net_cidr

    content {
      destination_prefix = static_route.value
      next_hop_address   = "${module.router.address[1]}"
    }
  }
}

resource "yandex_compute_instance" "web-instance" {
  name        = "web-instance"
  platform_id = "standard-v2"
  zone        = "ru-central1-c"

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = "${data.yandex_compute_image.ubuntu.id}"
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.subweb[0].id}"
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}


module "router" {
  source = "./.."

  name    = "bicycle"
  ssh-key = "${file("~/.ssh/id_rsa.pub")}"

  zone = "ru-central1-a"
  cidr = "192.168.0.0/24"

  networks = [
    {
      network_id  = "${yandex_vpc_network.net.id}",
      subnet_cidr = local.net_cidr,
    },
    {
      network_id  = "${yandex_vpc_network.web.id}",
      subnet_cidr = local.web_cidr,
    }
  ]
}
