variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "compartment_ocid" {}
variable "region" {}

provider "oci" {
  auth   = "InstancePrincipal"
  region = "${var.region}"
  
}

# provision bastion instance
/*
resource "oci_core_instance" "bastionInstance" {
  availability_domain = "XqVg:US-ASHBURN-AD-1"
  compartment_id      = "${var.compartment_ocid}"

  source_details {
    source_id   = "ocid1.image.oc1.iad.aaaaaaaannaquxy7rrbrbngpaqp427mv426rlalgihxwdjrz3fr2iiaxah5a"
    source_type = "image"
  }

  shape = "VM.Standard2.1"

  metadata {
    ssh_authorized_keys = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCuNyz+7hob57kYFjqr8l03x4kTALjTClgPYVbKqbFGJC18RYWb8Cxykwtrt3UM0M3HaAuGP17WJ5SxwcPSyqnfwvSqcXxfqCZSEh2n+FJdwsQujPC0/6TncK4IFfqfgehT53XteZ5mTNkzGAnBhI0+Mmij5gTJ0WMfEe8jtlqLjtKqCfY1QboU8cbC7HR2SIknrysRfA7lm9rf3LImpnt+s3xXU52Bms+3klV/jPd3mhnVmc7ZVIxihH/cGPaizc0Xi0iBjExpetxFevPc1HbJ7Y2aKByLwqEO36Xr9BqWeStLln/wkLgKp1XGRq/+qBNeu4Tcu8Qlt1giuOtWdyPZ jiayuaya@Violas-MacBook-Pro.local"
  }

  display_name = "bastionInstance_jenkins"

  create_vnic_details {
    subnet_id        = "ocid1.subnet.oc1.iad.aaaaaaaalcavtigilwjy44ynfy62k2k33jbkeeffidtlgm6vs4hvyf25flfq"
    assign_public_ip = true
  }
}

*/
