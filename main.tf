# TERRAFORM FILE TO CONFIGURE A GCP
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

# Create a VPC
resource "google_compute_network" "vpc_network" {
  name = "vpc-network"
}

# Create a Subnetwork
resource "google_compute_subnetwork" "timeapisubnet" {
  name          = "timeapisubnet"
  network       = google_compute_network.vpc_network.id
  ip_cidr_range = "10.0.0.0/16"
  region        = "us-central1"
}

# Create a Firewall Rule to allow internal/secure communication
resource "google_compute_firewall" "allow-internal" {
  name    = "allow-internal"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  source_ranges = ["10.0.0.0/16"]
}

# Create NAT Gateway
resource "google_compute_router" "nat_router" {
  name    = "nat-router"
  network = google_compute_network.vpc_network.id
  region  = "us-central1"
}

resource "google_compute_router_nat" "nat_gateway" {
  name                               = "nat-gateway"
  router                             = google_compute_router.nat_router.name
  region                             = google_compute_router.nat_router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}


# KUBERNETES
# Kubernetes Namespace
resource "kubernetes_namespace" "timeapi_ns" {
  metadata {
    name = "timeapi-namespace"
  }
}

# Kubernetes Deployment
resource "kubernetes_deployment" "timeapi_deployment" {
  metadata {
    name      = "timeapi-deployment"
    namespace = kubernetes_namespace.timeapi_ns.metadata[0].name
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "my-api"
      }
    }

    template {
      metadata {
        labels = {
          app = "my-api"
        }
      }

      spec {
        container {
          image = "gcr.io/${var.project_id}/timeapi:latest"
          name  = "time-api-container" #only allows"-"

          }
        }
      }
    }
  }


# Kubernetes Service
resource "kubernetes_service" "my_api_service" {
  metadata {
    name      = "my-api-service"
    namespace = kubernetes_namespace.timeapi_ns.metadata[0].name
  }

  spec {
    selector = {
      app = "my-api"
    }

    port {
      port        = 80
      target_port = 8080
    }
  }
}

# kubernetes provider config to connect to created cluster
  provider "kubernetes" { 
  host   = "https://${google_container_cluster.timeapi_cluster1.endpoint}"
  token  = data.google_client_config.default.access_token
 cluster_ca_certificate = base64decode(google_container_cluster.timeapi_cluster1.master_auth[0].cluster_ca_certificate)
}
data "google_client_config" "default" {}



# Kubernetes Ingress and specify the version number
resource "kubernetes_ingress_v1" "timeapi_ingress" {
  metadata {
    name      = "timeapi-ingress"
    namespace = kubernetes_namespace.timeapi_ns.metadata[0].name
    annotations = {
      "nginx.ingress.kubernetes.io/rewrite-target" = "/"
    }
  }

  spec {
    rule {
      http {
        path {
          path = "/time"
          path_type = "prefix" 
          backend {
            service_name = kubernetes_service.my_api_service.metadata[0].name
            service_port = 80
          }
        }
      }
    }

    tls {
      secret_name = "timeapi-tls"
    }
  }
}
