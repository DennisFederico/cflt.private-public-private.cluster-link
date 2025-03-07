output "primary_cluster" {
    value = "${module.primary_cluster.resources}"
}

output "jump_cluster" {
    value = "${module.jump_cluster.resources}"
}

output "dr_cluster" {
    value = "${module.dr_cluster.resources}"
}

output "proxy_data" {
    value = <<-EOT
    Primary DNS: "${module.primary_cluster.dns-domain}"
    DR DNS: "${module.dr_cluster.dns-domain}"
    PROXY Public IP: "${module.cc_proxy.cc_proxy_public_ip}"
    EOT

    sensitive = false
}

output "primary_cluster_access_data" {
    value = module.primary_apikey.access_data
}

output "dr_cluster_access_data" {
    value = module.primary_apikey.access_data
}
