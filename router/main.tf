data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-1804-lts"
}

resource "yandex_vpc_subnet" "subnet" {
  count = length(var.networks)

  v4_cidr_blocks = ["${cidrsubnet(var.cidr, 4, count.index)}"]
  zone           = "${var.zone}"
  network_id     = var.networks[count.index]["network_id"]
}

resource "yandex_compute_instance" "router" {
  name        = "router"
  platform_id = "standard-v2"
  zone        = "${var.zone}"

  resources {
    cores  = "${var.cores}"
    memory = "${var.memory}"
  }

  boot_disk {
    initialize_params {
      image_id = "${data.yandex_compute_image.ubuntu.id}"
    }
  }

  dynamic network_interface {
    for_each = yandex_vpc_subnet.subnet

    content {
      subnet_id = network_interface.value.id
    }
  }

  metadata = {
    user-data = templatefile("${path.module}/init.tpl", {
      ssh_key = var.ssh-key
      networks = [for i in range(length(var.networks)) : {
        index   = i
        address = cidrhost(cidrsubnet(var.cidr, 4, i), 1)
        subnets = var.networks[i].subnet_cidr
      }]
    })
  }
}


