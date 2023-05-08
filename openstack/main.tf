terraform {
	required_version =">= 0.12"
	required_providers {
		openstack = {
			source  = "terraform-provider-openstack/openstack"
			version = "~> 1.48.0"
		}
	}
}


provider "openstack" {
	user_name	= "admin"
	tenant_name	= "admin"
	password	= "secret"
	auth_url	= "http://192.168.244.129/identity"
}


# Create Instance
resource "openstack_images_image_v2" "Ubuntu1804" {
	name			= "Ubuntu1804"
	local_file_path 	= "/opt/stack/bionic-server-cloudimg-amd64.img"
	container_format 	= "bare"
	disk_format		= "qcow2"
}


# Create Router
resource "openstack_networking_router_v2" "router_1" {
	name			= "router_1"
	# Public Network ID
	external_network_id	= "00a5de1d-274d-4975-b690-b0751c03a913"
	admin_state_up		= true
}


# Create Private Network
resource "openstack_networking_network_v2" "internal_1" {
	name			= "internal_1"
	admin_state_up 		= true
}


# Set Private Network Subnet
resource "openstack_networking_subnet_v2" "subnet_1" {
	name			= "subnet_1"
	network_id 		= openstack_networking_network_v2.internal_1.id
	cidr			= "10.10.10.0/24"
	ip_version		= 4
}


# Set Router Interface
resource "openstack_networking_router_interface_v2" "interface_1" {
	router_id		= openstack_networking_router_v2.router_1.id
	subnet_id		= openstack_networking_subnet_v2.subnet_1.id
}


# Create Security Group
resource "openstack_networking_secgroup_v2" "secgroup_1" {
	name			= "secgroup_1"
	description		= "secgroup_1"
}


resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_1" {
  	direction         = "ingress"
	ethertype         = "IPv4"
 	protocol          = "tcp"
  	port_range_min    = 22
  	port_range_max    = 22
	remote_ip_prefix  = "0.0.0.0/0"
 	security_group_id = openstack_networking_secgroup_v2.secgroup_1.id
}


# Create Instance
resource "openstack_compute_instance_v2" "instance_1" {
	name			= "instance_1"
	image_id		= "${openstack_images_image_v2.Ubuntu1804.id}"
	flavor_id		= "2"
	key_pair		= "terraform_key"
	security_groups = [openstack_networking_secgroup_v2.secgroup_1.name]

	network {
		name = openstack_networking_network_v2.internal_1.name
	}
}


# Create Floating IP
resource "openstack_networking_floatingip_v2" "floatip_1" {
        pool = "public"
}


resource "openstack_compute_floatingip_associate_v2" "floatip_1" {
        floating_ip     = openstack_networking_floatingip_v2.floatip_1.address
        instance_id     = openstack_compute_instance_v2.instance_1.id
}

