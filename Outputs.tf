output "kubernetes_cluster_name" {
  value = google_container_cluster.timeapi_cluster1.name
}

output "cluster_ca_certificate" {
  value = google_container_cluster.timeapi_cluster1.master_auth[0].cluster_ca_certificate  # Update the resource name
}
output "gke_service_account_private_key" {
  value = google_service_account_key.gke_sa_key.private_key
  sensitive = true
}
