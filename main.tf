provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

resource "google_project_service" "compute_service" {
  project = var.project_id
  service = var.service
}

resource "google_compute_network" "vpc_network" {
  name                    = "terraform-network"
  auto_create_subnetworks = false
  delete_default_routes_on_create = false
  depends_on = [
    google_project_service.compute_service
  ]
}

resource "google_compute_subnetwork" "private_network" {
  name          = "private-network"
  ip_cidr_range = "10.2.0.0/16"
  network       = google_compute_network.vpc_network.self_link
}

resource "google_compute_route" "private_network_internet_route" {
  name             = "private-network-internet"
  dest_range       = "0.0.0.0/0"
  network          = google_compute_network.vpc_network.self_link
  next_hop_gateway = "default-internet-gateway"
  priority    = 100
}

# may delete this
resource "google_compute_router" "router" {
  name    = "quickstart-router"
  network = google_compute_network.vpc_network.self_link
}

resource "google_compute_router_nat" "nat" {
  name                               = "quickstart-router-nat"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

#instance One
resource "google_compute_instance" "vm_instance" {
  name         = "nginx-instance"
  machine_type = var.machine_type

  tags = ["nginx-instance"]

  boot_disk {
    initialize_params {
      image = var.image
    }
  }

    metadata_startup_script = <<EOT
curl -fsSL https://get.docker.com -o get-docker.sh && 
sudo sh get-docker.sh && 
sudo service docker start && 
sudo docker run -p 8080:8080 -d gcr.io/myapplication-348521/instance-one:latest
EOT
   
  network_interface {
    network = google_compute_network.vpc_network.self_link
    subnetwork = google_compute_subnetwork.private_network.self_link    
    access_config {
      network_tier = "STANDARD"
    }
  }
}


#Instance Two
resource "google_compute_instance" "vm_instance2" {
  name         = "nginx-instance2"
  machine_type = var.machine_type

  tags = ["nginx-instance"]

  boot_disk {
    initialize_params {
      image = var.image
    }
  }

      metadata_startup_script = <<EOT
curl -fsSL https://get.docker.com -o get-docker.sh && 
sudo sh get-docker.sh && 
sudo service docker start && 
sudo docker run -p 8080:8080 -d gcr.io/myapplication-348521/instance-two:latest
EOT

  network_interface {
    network = google_compute_network.vpc_network.self_link
    subnetwork = google_compute_subnetwork.private_network.self_link    
    access_config {
      network_tier = "STANDARD"
    }
  }
}


resource "google_compute_firewall" "public_ssh" {
  name    = "public-ssh"
  network = google_compute_network.vpc_network.self_link

  allow {
    protocol = "tcp"
    ports    = ["22","8080"]
  }

    direction = "INGRESS"
    source_ranges = ["0.0.0.0/0"]
    target_tags = ["nginx-instance"]
 }


resource "google_compute_instance_group" "webservers" {
  name        = "terraform-webservers"
  description = "Terraform test instance group"

  instances = [
    google_compute_instance.vm_instance.self_link,
    google_compute_instance.vm_instance2.self_link,
  ]

  named_port {
    name = "http"
    port = "8080"
  }
}

# Global health check
resource "google_compute_health_check" "webservers-health-check" {
  name        = "webservers-health-check"
  description = "Health check via tcp"

  timeout_sec         = 5
  check_interval_sec  = 10
  healthy_threshold   = 3
  unhealthy_threshold = 2

  tcp_health_check {
    port_name          = "http"
  }

  depends_on = [
    google_project_service.compute_service
  ]
}

# Global backend service
resource "google_compute_backend_service" "webservers-backend-service" {

  name                            = "webservers-backend-service"
  timeout_sec                     = 30
  connection_draining_timeout_sec = 10
  load_balancing_scheme = "EXTERNAL"
  protocol = "HTTP"
  port_name = "http"
  health_checks = [google_compute_health_check.webservers-health-check.self_link]

  backend {
    group = google_compute_instance_group.webservers.self_link
    balancing_mode = "UTILIZATION"
  }
}

resource "google_compute_url_map" "default" {

  name            = "website-map"
  default_service = google_compute_backend_service.webservers-backend-service.self_link
}


# Global http proxy
resource "google_compute_target_http_proxy" "default" {

  name    = "website-proxy"
  url_map = google_compute_url_map.default.id
}

# Regional forwarding rule
resource "google_compute_forwarding_rule" "webservers-loadbalancer" {
  name                  = "website-forwarding-rule"
  ip_protocol           = "TCP"
  port_range            = 80
  load_balancing_scheme = "EXTERNAL"
  network_tier          = "STANDARD"
  target                = google_compute_target_http_proxy.default.id
}


resource "google_compute_firewall" "load_balancer_inbound" {
  name    = "nginx-load-balancer"
  network = google_compute_network.vpc_network.self_link

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

   direction = "INGRESS"
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags = ["nginx-instance"]
}


# #DB
resource "google_sql_database_instance" "cloudsql-instance-qa" {
  
  database_version = "MYSQL_5_7"
  name             = "cloudsql-instance-qa-b"
  project          = var.project_id
  region           = var.region
  deletion_protection = false
  settings {
    activation_policy = "ALWAYS"
    availability_type = "ZONAL"

    backup_configuration {
      binary_log_enabled             = "true"
      enabled                        = "true"
      point_in_time_recovery_enabled = "false"
      start_time                     = "15:00"
    }

    disk_autoresize        = "true"
    disk_size              = "10"
    disk_type              = "PD_SSD"

    ip_configuration {
      ipv4_enabled    = "true"
     
    }

    location_preference {
      zone = var.zone
    }

    maintenance_window {
      day  = "7"
      hour = "4"
    }

 tier             = "db-f1-micro"
    
  }
}