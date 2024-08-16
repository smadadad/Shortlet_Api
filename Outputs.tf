output "kubernetes_cluster_name" {
  value = google_container_cluster.timeapi_cluster.name
}

output "service_external_ip" {
  value = google_compute_address.external_ip.address
}

output "cluster_ca_certificate" {
  value = google_container_cluster.timeapi_cluster.master_auth[0].cluster_ca_certificate
}
