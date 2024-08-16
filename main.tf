# Google Provider Configuration
provider "google" {
  credentials = var.gcp_credentials
  project     = var.project_id
  region      = "us-central1"
}

# Create a service account for GKE
resource "google_service_account" "gke_service_account" {
  account_id   = "gke-cluster-sa"
  display_name = "GKE Cluster Service Account"
}

# Google Kubernetes Engine (GKE) cluster
resource "google_container_cluster" "timeapi_cluster1" {
  name     = "timeapi-cluster1"
  location = "us-central1"

  initial_node_count = 1
  node_config {
    machine_type = "e2-medium"
    disk_size_gb = 75
    service_account = google_service_account.gke_service_account.email
  }
}

# Assign IAM roles to the service account
resource "google_project_iam_member" "gke_cluster_admin" {
  project = var.project_id
  role    = "roles/container.clusterAdmin"
  member  = "serviceAccount:${google_service_account.gke_service_account.email}"
}

resource "google_project_iam_member" "gke_compute_admin" {
  project = var.project_id
  role    = "roles/compute.admin"
  member  = "serviceAccount:${google_service_account.gke_service_account.email}"
}

resource "google_project_iam_member" "gke_iam_service_account_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.gke_service_account.email}"
}

# Data source to check for an existing VPC network
data "google_compute_network" "existing_vpc_network" {
  name    = "vpc-network"
  project  = var.project_id
}

# Create a VPC network only if it doesn't exist
resource "google_compute_network" "vpc_network" {
  count = length(data.google_compute_network.existing_vpc_network.id) == 0 ? 1 : 0
  name  = "vpc-network"
}

# Data source to check for an existing Subnetwork
data "google_compute_subnetwork" "existing_subnet" {
  name    = "timeapisubnet"
  region  = "us-central1"
  project = var.project_id
}

# Create a Subnetwork only if it doesn't exist
resource "google_compute_subnetwork" "timeapisubnet" {
  count         = length(data.google_compute_subnetwork.existing_subnet.id) == 0 ? 1 : 0
  name          = "timeapisubnet"
  network       = google_compute_network.vpc_network[0].id
  ip_cidr_range = "10.0.0.0/16"
  region        = "us-central1"
}

# Create a Firewall Rule
resource "google_compute_firewall" "allow-internal" {
  count   = length(data.google_compute_network.existing_vpc_network.id) > 0 || google_compute_network.vpc_network.*.id
