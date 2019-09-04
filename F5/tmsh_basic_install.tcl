create net vlan bigip1.external_vlan interfaces add { 1.1 { untagged } }
create net vlan bigip1.internal_vlan interfaces add { 1.2 { untagged } }

create net self bigip1.external_selfip address 10.1.20.241/24 vlan bigip1.external_vlan allow-service default
create net self bigip1.internal_selfip address 10.1.10.241/24 vlan bigip1.internal_vlan allow-service default

create net route Default_Gateway network 0.0.0.0/0 gw 10.1.10.2
save sys config