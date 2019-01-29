variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "compartment_ocid" {}
variable "region" {}

provider "oci" {
  auth   = "InstancePrincipal"
  region = "us-ashburn-1"
}

resource "oci_core_virtual_network" "demoVCN" {
  cidr_block     = "10.0.0.0/16"
  dns_label      = "demoVCN"
  compartment_id = "${var.compartment_ocid}"
  display_name   = "demoVCN"
}

//Creating Internet and NAT gateways
resource "oci_core_internet_gateway" "IGW" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "IGW"
  enabled        = true
  vcn_id         = "${oci_core_virtual_network.demoVCN.id}"
}

resource "oci_core_nat_gateway" "nat_gateway" {
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${oci_core_virtual_network.demoVCN.id}"
  display_name   = "nat_gateway"
}

//create two route tables
resource "oci_core_route_table" "PublicSubnetRT" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "PublicSubnetRT"
  vcn_id         = "${oci_core_virtual_network.demoVCN.id}"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = "${oci_core_internet_gateway.IGW.id}"
  }
}

resource "oci_core_route_table" "PrivateSubnetRT" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "PrivateSubnetRT"
  vcn_id         = "${oci_core_virtual_network.demoVCN.id}"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = "${oci_core_nat_gateway.nat_gateway.id}"
  }
}

//create securitylists for each subnet (bastion subnet, private db1 subnet, private db2 subnet)
resource "oci_core_security_list" "BastionSecurityList" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "BastionSecurityList"
  vcn_id         = "${oci_core_virtual_network.demoVCN.id}"

  ingress_security_rules = [
    {
      protocol    = "6"
      source      = "0.0.0.0/0"
      source_type = "CIDR_BLOCK"

      tcp_options {
        min = 22
        max = 22
      }
    },
    {
      protocol    = "1"
      source      = "10.0.0.0/16"
      source_type = "CIDR_BLOCK"

      icmp_options {
        type = 3
      }
    },
    {
      protocol    = "1"
      source      = "0.0.0.0/0"
      source_type = "CIDR_BLOCK"

      icmp_options {
        type = 3
        code = 4
      }
    },
  ]

  egress_security_rules = [{
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
  }]
}

resource "oci_core_security_list" "PrivateDB1SecurityList" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "PrivateDB1SecurityList"
  vcn_id         = "${oci_core_virtual_network.demoVCN.id}"

  ingress_security_rules = [
    {
      protocol    = "6"
      source      = "10.0.0.0/24"
      source_type = "CIDR_BLOCK"

      tcp_options {
        min = 22
        max = 22
      }
    },
    {
      protocol    = "6"
      source      = "10.0.2.0/24"
      source_type = "CIDR_BLOCK"

      tcp_options {
        min = 1521
        max = 1521
      }
    },
  ]

  egress_security_rules = [
    {
      destination      = "0.0.0.0/0"
      destination_type = "CIDR_BLOCK"
      protocol         = "all"
    },
    {
      destination      = "10.0.2.0/24"
      destination_type = "CIDR_BLOCK"
      protocol         = "6"

      tcp_options {
        min = 1521
        max = 1521
      }
    },
  ]
}

resource "oci_core_security_list" "PrivateDB2SecurityList" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "PrivateDB2SecurityList"
  vcn_id         = "${oci_core_virtual_network.demoVCN.id}"

  ingress_security_rules = [
    {
      protocol    = "6"
      source      = "10.0.0.0/24"
      source_type = "CIDR_BLOCK"

      tcp_options {
        min = 22
        max = 22
      }
    },
    {
      protocol    = "6"
      source      = "10.0.1.0/24"
      source_type = "CIDR_BLOCK"

      tcp_options {
        min = 1521
        max = 1521
      }
    },
  ]

  egress_security_rules = [
    {
      destination      = "0.0.0.0/0"
      destination_type = "CIDR_BLOCK"
      protocol         = "all"
    },
    {
      destination      = "10.0.1.0/24"
      destination_type = "CIDR_BLOCK"
      protocol         = "6"

      tcp_options {
        min = 1521
        max = 1521
      }
    },
  ]
}

//create 3 subnets

resource "oci_core_subnet" "BastionSubnet" {
  availability_domain        = "ToGS:US-ASHBURN-AD-3"
  cidr_block                 = "10.0.0.0/24"
  compartment_id             = "${var.compartment_ocid}"
  display_name               = "BastionSubnet"
  dns_label                  = "bastionDNS"
  vcn_id                     = "${oci_core_virtual_network.demoVCN.id}"
  prohibit_public_ip_on_vnic = false
  route_table_id             = "${oci_core_route_table.PublicSubnetRT.id}"

  security_list_ids = [
    "${oci_core_security_list.BastionSecurityList.id}",
  ]
}

resource "oci_core_subnet" "db1Subnet" {
  availability_domain        = "ToGS:US-ASHBURN-AD-3"
  cidr_block                 = "10.0.1.0/24"
  compartment_id             = "${var.compartment_ocid}"
  display_name               = "db1Subnet"
  dns_label                  = "db1DNS"
  vcn_id                     = "${oci_core_virtual_network.demoVCN.id}"
  prohibit_public_ip_on_vnic = true
  route_table_id             = "${oci_core_route_table.PrivateSubnetRT.id}"

  security_list_ids = [
    "${oci_core_security_list.PrivateDB1SecurityList.id}",
  ]
}

resource "oci_core_subnet" "db2Subnet" {
  availability_domain        = "ToGS:US-ASHBURN-AD-2"
  cidr_block                 = "10.0.2.0/24"
  compartment_id             = "${var.compartment_ocid}"
  display_name               = "db2Subnet"
  dns_label                  = "db2DNS"
  vcn_id                     = "${oci_core_virtual_network.demoVCN.id}"
  prohibit_public_ip_on_vnic = true
  route_table_id             = "${oci_core_route_table.PrivateSubnetRT.id}"

  security_list_ids = [
    "${oci_core_security_list.PrivateDB2SecurityList.id}",
  ]
}

//provision two VMs for the databases

resource "oci_core_instance" "dbSystem1" {
  availability_domain = "ToGS:US-ASHBURN-AD-3"
  compartment_id      = "${var.compartment_ocid}"
  shape               = "VM.Standard2.4"

  metadata {
    ssh_authorized_keys = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCuNyz+7hob57kYFjqr8l03x4kTALjTClgPYVbKqbFGJC18RYWb8Cxykwtrt3UM0M3HaAuGP17WJ5SxwcPSyqnfwvSqcXxfqCZSEh2n+FJdwsQujPC0/6TncK4IFfqfgehT53XteZ5mTNkzGAnBhI0+Mmij5gTJ0WMfEe8jtlqLjtKqCfY1QboU8cbC7HR2SIknrysRfA7lm9rf3LImpnt+s3xXU52Bms+3klV/jPd3mhnVmc7ZVIxihH/cGPaizc0Xi0iBjExpetxFevPc1HbJ7Y2aKByLwqEO36Xr9BqWeStLln/wkLgKp1XGRq/+qBNeu4Tcu8Qlt1giuOtWdyPZ jiayuaya@Violas-MacBook-Pro.local"
  }

  display_name = "dbSystem1"

  source_details {
    source_id   = "ocid1.image.oc1.iad.aaaaaaaageeenzyuxgia726xur4ztaoxbxyjlxogdhreu3ngfj2gji3bayda"
    source_type = "image"
  }

  create_vnic_details {
    subnet_id        = "${oci_core_subnet.db1Subnet.id}"
    assign_public_ip = false
  }
}

resource "oci_core_instance" "dbSystem2" {
  availability_domain = "ToGS:US-ASHBURN-AD-2"
  compartment_id      = "${var.compartment_ocid}"
  shape               = "VM.Standard2.4"

  metadata {
    ssh_authorized_keys = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCuNyz+7hob57kYFjqr8l03x4kTALjTClgPYVbKqbFGJC18RYWb8Cxykwtrt3UM0M3HaAuGP17WJ5SxwcPSyqnfwvSqcXxfqCZSEh2n+FJdwsQujPC0/6TncK4IFfqfgehT53XteZ5mTNkzGAnBhI0+Mmij5gTJ0WMfEe8jtlqLjtKqCfY1QboU8cbC7HR2SIknrysRfA7lm9rf3LImpnt+s3xXU52Bms+3klV/jPd3mhnVmc7ZVIxihH/cGPaizc0Xi0iBjExpetxFevPc1HbJ7Y2aKByLwqEO36Xr9BqWeStLln/wkLgKp1XGRq/+qBNeu4Tcu8Qlt1giuOtWdyPZ jiayuaya@Violas-MacBook-Pro.local"
  }

  display_name = "dbSystem2"

  source_details {
    source_id   = "ocid1.image.oc1.iad.aaaaaaaageeenzyuxgia726xur4ztaoxbxyjlxogdhreu3ngfj2gji3bayda"
    source_type = "image"
  }

  create_vnic_details {
    subnet_id        = "${oci_core_subnet.db2Subnet.id}"
    assign_public_ip = false
  }
}

//provision bastion instance

resource "oci_core_instance" "bastionInstance" {
  availability_domain = "ToGS:US-ASHBURN-AD-3"
  compartment_id      = "${var.compartment_ocid}"

  source_details {
    source_id   = "ocid1.image.oc1.iad.aaaaaaaageeenzyuxgia726xur4ztaoxbxyjlxogdhreu3ngfj2gji3bayda"
    source_type = "image"
  }

  shape = "VM.Standard2.4"

  metadata {
    ssh_authorized_keys = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCuNyz+7hob57kYFjqr8l03x4kTALjTClgPYVbKqbFGJC18RYWb8Cxykwtrt3UM0M3HaAuGP17WJ5SxwcPSyqnfwvSqcXxfqCZSEh2n+FJdwsQujPC0/6TncK4IFfqfgehT53XteZ5mTNkzGAnBhI0+Mmij5gTJ0WMfEe8jtlqLjtKqCfY1QboU8cbC7HR2SIknrysRfA7lm9rf3LImpnt+s3xXU52Bms+3klV/jPd3mhnVmc7ZVIxihH/cGPaizc0Xi0iBjExpetxFevPc1HbJ7Y2aKByLwqEO36Xr9BqWeStLln/wkLgKp1XGRq/+qBNeu4Tcu8Qlt1giuOtWdyPZ jiayuaya@Violas-MacBook-Pro.local"
  }

  display_name = "bastionInstance"

  create_vnic_details {
    subnet_id        = "${oci_core_subnet.BastionSubnet.id}"
    assign_public_ip = true
  }
}
