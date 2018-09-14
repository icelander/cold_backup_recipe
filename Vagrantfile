# -*- mode: ruby -*-
# vi: set ft=ruby :

MATTERMOST_PASSWORD = 'really_secure_password'

servers = [
			{
				hostname: 'hotserver',
				ip_addr: '192.168.2.2',
				live: true
			},
			{
				hostname: 'coldserver',
				ip_addr: '192.168.2.3',
				live: false
			}
		  ]

Vagrant.configure("2") do |config|
	config.vm.box = "bento/ubuntu-16.04"

	servers.each do |server| 
		config.vm.define server[:hostname] do |box|
			box.vm.network "private_network", ip: server[:ip_addr]
			box.vm.hostname = server[:hostname]

			setup_script = File.read('setup.sh')

			setup_script.gsub!('#MATTERMOST_PASSWORD', MATTERMOST_PASSWORD)

			box.vm.provision :shell, inline: setup_script, run: 'once'

			if server[:live] == true
				box.vm.provision :shell, path: 'hotserver_setup.sh', run: 'once'
			else
				box.vm.provision :shell, path: 'coldserver_setup.sh', run: 'once'
			end
		end
	end	
end