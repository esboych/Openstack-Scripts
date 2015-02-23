#Stages configuration
stage {'zero': } ->
stage {'first': } ->
stage {'openstack-custom-repo': } ->
stage {'netconfig': } ->
stage {'corosync_setup': } ->
stage {'openstack-firewall': } -> Stage['main']

$fuel_settings = parseyaml($astute_settings_yaml)

prepare_network_config($::fuel_settings['network_scheme'])

class advanced_node_netconfig {
    $sdn = generate_network_config()
    notify {"SDN: ${sdn}": }
}

class {'l23network': use_ovs=>$use_quantum, stage=> 'netconfig'}
class {'advanced_node_netconfig': stage => 'netconfig' }

