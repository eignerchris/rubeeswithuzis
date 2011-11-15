require 'rubygems'
require 'fog'
require 'pp'
require 'optparse'

AMI_IMAGE_ID = 'ami-50e62239'

File.delete('results.txt') if File.exists?('results.txt')
$log = File.open('results.txt', 'a')

options = {}

optparse = OptionParser.new do |opts|
  opts.banner = "Usage: rubeeswithuzies.rb [options]"

  options[:servers] = 1
  opts.on( '-s', '--servers COUNT', Integer, 'Number of servers to use in attack' ) do |val|
    options[:servers] = val
  end

  options[:'requests'] = 1
  opts.on( '-n', '--requests COUNT', Integer, 'Number of requests for each server to send' ) do |val|
    options[:'requests'] = val
  end

  options[:'concurrency'] = 1
  opts.on( '-c', '--concurrency COUNT', Integer, 'Number of concurrent requests for each server to send' ) do |val|
    options[:'concurrency'] = val
  end
  
  options[:url] = nil
  opts.on( '-u', '--url URL', 'URL to attack' ) do |val|
    options[:url] = val
  end
  
  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end
end

optparse.parse!

# create connection to amazon
puts "Creating connection to AWS"
connection = Fog::Compute.new(:provider => 'AWS')

# spawn threads and create amazon instances
puts "Spinning up #{options[:servers]} servers"
servers = []
server_loading_threads = []
options[:servers].times do |n|
  server_loading_threads << Thread.new do 
	  servers << connection.servers.bootstrap(:image_id => AMI_IMAGE_ID, 
	                                          :private_key_path => '~/.ssh/id_rsa', 
	                                          :public_key_path => '~/.ssh/id_rsa.pub', 
	                                          :username => 'ubuntu')
	end
end

# cleanup threads
server_loading_threads.each { |t|  t.join }

# wait for instances to be ready
servers.map { |server| server.wait_for { ready? }; puts "Server ready" }

# launch attack
ssh_threads = []
options[:servers].times do |n|
  ssh_threads << Thread.new(servers[n]) do |serv|
    puts "Server #{n} blasting #{options[:url]}"
    result = serv.ssh("ab -n #{options[:requests]} -c #{options[:concurrency]} #{options[:url]}").first.stdout
    $log.write result
    $log.write "\n\n=========================================\n\n" 
  end
end

# cleanup threads
ssh_threads.each { |t|  t.join }

# cleanup instances: time = money
puts "Done blasting"
servers.map { |server| server.destroy }
puts "Servers destroyed"

$log.close