variable "name" {
  type = string
}

variable "cidr" {
  type = string
}

variable "ssh-key" {
  type = string
}

variable "zone" {
  type    = string
  default = "ru-central1-a"
}

variable "cores" {
  type    = string
  default = "2"
}

variable "memory" {
  type    = string
  default = "4"
}

variable "networks" {
  type = list(object({
    network_id  = string
    subnet_cidr = list(string)
  }))
}
