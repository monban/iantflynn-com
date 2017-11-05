variable "do_token" {}
variable "ssh_key" {}

provider "digitalocean" {
  token = "${var.do_token}"
}

resource "digitalocean_ssh_key" "do_ssh_key" {
  name       = "default_key"
  public_key = "${var.ssh_key}"
}

data "template_file" "cloud_config" {
  template = "${file("cloud-config.yml.tpl")}"
  vars {
    ssh_key = "${var.ssh_key}"
  }
}

resource "digitalocean_droplet" "core" {
  image              = "coreos-stable"
  name               = "core"
  region             = "nyc1"
  size               = "512mb"
  private_networking = true
  ssh_keys           = ["${digitalocean_ssh_key.do_ssh_key.id}"]
  user_data          = "${data.template_file.cloud_config.rendered}"
  tags               = ["${digitalocean_tag.webserver.id}"]
}

resource "digitalocean_firewall" "webserver_firewall" {
  name = "webserver"
  tags = ["${digitalocean_tag.webserver.id}"]

  inbound_rule = [
    {
      protocol         = "tcp"
      port_range       = "22"
      source_addresses = ["0.0.0.0/0", "2002:1:2::/48"]
    },
    {
      protocol         = "tcp"
      port_range       = "80"
      source_addresses = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol         = "tcp"
      port_range       = "443"
      source_addresses = ["0.0.0.0/0", "::/0"]
    },
  ]

  outbound_rule {
    protocol              = "udp"
    port_range            = "53"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

resource "digitalocean_tag" "webserver" {
  name = "webserver"
}
