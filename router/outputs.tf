output "address" {
  value       = yandex_compute_instance.router.network_interface.*.ip_address
  description = "The list of router addresses"
}
