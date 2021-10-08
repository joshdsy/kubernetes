provider "google" {
  project = "${var.project_id}"
  region  = "${var.region}"
  zone    = "${var.zone}"
}

resource "google_compute_firewall" "allow-kube-api" {
  name    = "allow-kube-api"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["6443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["kube-api"]
}

resource "google_compute_firewall" "allow-nodeports" {
  name    = "allow-nodeports"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["30000-32767"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["nodeports"]
}

resource "google_compute_instance_template" "default" {
  name = "kubernetes-nodes-instances"
  description = "This template is used to create Kubernetes nodes instances."

  tags = ["kube-api", "nodeports"]

  labels = {
    environment = "medium"
  }

  instance_description = "description assigned to instances"
  machine_type         = "n1-standard-2"
  can_ip_forward       = true

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  // Create a new boot disk from an image
  disk {
    source_image = "debian-cloud/debian-9"
    auto_delete  = true
    boot         = true
  }

  network_interface {
  network = "default"
  access_config {
    // Ephemeral IP
    }
  }
  metadata = {
    ssh-keys = "saphoooo:${file("id_rsa.pub")}"
  }

  metadata_startup_script = "${file("startup.sh")}"

  service_account {
    scopes = ["storage-full", "cloud-platform", "compute-rw", "logging-write", "monitoring", "service-control", "service-management"]
  }
}

resource "google_compute_region_instance_group_manager" "default" {
  name               = "kubernetes-node-group-manager"
  instance_template  = "${google_compute_instance_template.default.self_link}"
  base_instance_name = "kubernetes-node"
  region             = "europe-west2"
  distribution_policy_zones  = ["europe-west2-a", "europe-west2-b", "europe-west2-c"]
  target_size        = "3"
}