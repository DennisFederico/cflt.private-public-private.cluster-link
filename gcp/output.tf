output "primary_cluster" {
    value = "${module.gcp_private_primary.resources}"
}
output "jump_cluster" {
    value = "${module.jump_cluster.resources}"
}
output "dr_cluster" {
    value = "${module.gcp_private_dr.resources}"
}