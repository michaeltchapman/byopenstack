. openrc

wget --quiet http://download.cirros-cloud.net/0.3.2/cirros-0.3.2-x86_64-disk.img

# Add it to glance so that we can use it in Openstack
glance add name='cirros_image' is_public=true container_format=bare disk_format=qcow2 < cirros-0.3.2-x86_64-disk.img

nova keypair-add test > test.private
chmod 0600 test.private

neutron net-create net1
neutron subnet-create net1 10.0.0.0/24

nova secgroup-add-rule default icmp -1 -1 0.0.0.0/0
nova secgroup-add-rule default tcp 22 22 0.0.0.0/0

nova boot --flavor 1 --image cirros_image --key_name test --config-drive true testvm
