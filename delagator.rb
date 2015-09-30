#! /usr/bin/env ruby
require 'erb'
require 'yaml'


phone_carriers = {
	sprint:   '@messaging.sprintpcs.com',
	cricket:  '@sms.mycricket.com',
	tmobile:  '@tmomail.net',
	att:      '@txt.att.net',
	verizon:  '@vtext.com',
	republic: '@text.republicwireless.com'
}

#
template = ERB.new(File.read('PBS-submitter.erb'))

begin
	# Attempt to load the config file
	config = YAML::load_file('config.yml')
	puts "\033[1mDelagator configuration loaded from 'config.yml'.\nModify this file directly or delete it to use a different configuration.\033[0m"
rescue
	# Or create one
	puts "\033[1mIt doesn't look like you have configured delagator yet. \nPlease answer some questions:\033[0m"
	
	# Setup passwordless ssh login
	response = nil
	while not ['y','n','c'].include? response
		print "Have you setup passwordless login to the cluster? [N/y/c] "
		response = gets.chomp.downcase
		if response == 'n' or response == ""
			print "\033[1;91mRunning 'key-login.sh'...\033[0m\n"
			system("./key-login.sh")
			print "\033[1;91m'key-login.sh' completed.\033[0m\n"	
		elsif response =='c'
			abort("\033[1mPasswordless login is required for delagator. Please run 'key-login.sh' to do so.\033[0m")
		end
	end
	print "What is the ssh nickname for the cluster that you chose? "
	ssh_nick  = gets.chomp.strip()
	test = `ssh -q #{ssh_nick} pwd;`.chomp
	if test == ""
		puts "\033[1mThe ssh nickname provided doesn't seem to work. \nPlease fix 'ssh [nickname]'' or run 'key-login.sh' before continuing with delagator.\033[0m"
		exit
	end
	# Test that the passwordless ssh login and ssh alias works
	home_dir = test
	puts "Great! 'ssh \033[1;34m#{ssh_nick}\033[0m' seems to be working.\nYour home directory appears to be: \033[1;34m#{home_dir}\033[0m"
	puts "\033[1mDelagator will store projects on the cluster under #{home_dir}/[project name]/ by default.\nYou can change this in 'config.yml'\033[0m"
	
	# Ask if texting should be performed after job completion
	response = nil
	do_text = false
	while not ['y','n'].include? response
		print "Would you like text messages sent to you when your jobs have completed? [N/y] "
		response = gets.chomp.downcase
		if response == 'n' or response == ""
			break
		elsif response =='y'
			phone_num = 0
			while phone_num.to_s.length != 10
				print "What is your 10 digit phone number? "
				begin
					phone_num  = gets.chomp.tr('-','').to_i
				rescue
					phone_num = ""
				end
			end
			print "What is your carrier? [sprint/cricket/tmobile/att/verizon/republic/cancel] "
			carrier  = gets.chomp.downcase
			if not phone_carriers.keys.include? carrier.to_sym
				break
			end
			email_addr = phone_num.to_s + phone_carriers[carrier.to_sym]
			#puts "Emailing to #{email_addr}"
			do_text = true
		end
	end

	# Save the config file and quit
	config = {ssh_nick: ssh_nick, home_dir: home_dir, email_addr: email_addr, do_text: do_text}
	File.open('config.yml', 'w') {|f| f.write config.to_yaml }
	puts "\033[1mGreat! The delagator has been configured.\nPlease run this script again to submit a job.\033[0m"
	exit
end


# Load the config file
config = YAML::load_file('config.yml')

# Ask for the project name
puts "\033[1m\nPlease name your project.\nCode and files will be organized in a folder on the cluster under this name.\033[0m"
print "What is this project's name? "
project_name = gets.chomp

# Ask for the script location 
puts "\033[1m\nPlease enter the name of the script you'd like to run on the cluster."
puts "Just give the script location (and name); script parameters should go in 'settings.txt'."
puts "Your script should also start with the line: '#! /usr/bin/env [programming language]'.\033[0m"
print "Where is the script located? "
script_call = gets.chomp

# As for the number of nudes
puts "\033[1m\nPlease enter the number of nodes you would like to queue.\nOne node for each line of your setting file is appropriate.\033[0m"
print "How many nodes would you like? "
num_nodes = gets.chomp

# Ask if file should be transfered
puts "\033[1m\nThis script will optionally transfer input datafiles to the cluster on your behalf."
puts "To do so, enter a list of files to transfer in the 'transfers.txt' file. Wildcard use is acceptable.\033[0m"
do_transfer = false
response = nil
while not ['y','n'].include? response
	print "Would you like to transfer files to the cluster? [N/y] "
	response = gets.chomp.downcase
	if response == 'n' or response == ""
		puts "\033[1mOk, please make sure file path information is correct in your 'settings.txt' file!\033[0m"
		break
	elsif response =='y'
		puts "\033[1mOk, file listed in 'transfers.txt' will be transfered.\033[0m"
		do_transfer = true
	end
end

# Define some paths and file names
project_dir   = File.join(config[:home_dir], project_name)
output_dir    = File.join(project_dir, "output/sge-output")
error_dir     = File.join(project_dir, "errors/sge-error")
settings_file = "settings.txt"
pbs_submitter = "PBS-submitter.sh"
texter        = "txt-when-done.sh"

# Generate and display the PBS submitter script
puts "\033[1m\nThe following cluster script has been generated:\033[0m"
puts "-------------------- generated PBS script --------------------"
print "\033[1;91m"
puts template.result()
print "\033[0m"
puts "--------------------------------------------------------------"
File.open(pbs_submitter, 'w') { |file| file.write(template.result()) }

# Make the project directory
puts "\033[1m\nCreating folders and transfering code...\033[0m"
[
	"ssh -q #{config[:ssh_nick]} mkdir #{project_dir}",
	"ssh -q #{config[:ssh_nick]} mkdir #{project_dir}/input",
	"ssh -q #{config[:ssh_nick]} mkdir #{project_dir}/output",
	"ssh -q #{config[:ssh_nick]} mkdir #{project_dir}/errors",
].each{|cmd| puts cmd; `#{cmd}`;}

# Transfer the scripts and settings file
[
	"scp #{script_call} #{config[:ssh_nick]}:#{project_dir}/#{File.basename script_call}",
	"scp #{pbs_submitter} #{config[:ssh_nick]}:#{project_dir}/PBS-submitter.sh",
	"scp #{settings_file} #{config[:ssh_nick]}:#{project_dir}/settings.txt",
	"scp #{texter} #{config[:ssh_nick]}:#{project_dir}/txt-when-done.sh",
	"ssh -q #{config[:ssh_nick]} chmod +x #{project_dir}/*.sh"
].each{|cmd| puts cmd; `#{cmd}`;}



# Transfer files if requested
if do_transfer
	puts "\033[1m\nTransfering datafiles...\033[0m"
	transfers = File.open('transfers.txt','r')
	for file in transfers
		file = file.chomp
		cmd =  "scp #{file} #{config[:ssh_nick]}:#{project_dir}/input"
		`#{cmd}`
	end
end

puts "\033[1mSubmitting job...\033[0m"
cmd = "ssh -q #{config[:ssh_nick]} qsub #{project_dir}/#{pbs_submitter}"
job_id = `#{cmd}`.split(".")[0].delete!("[]")


if config[:do_text]
	# Text
	puts "\033[1mWill send a text to #{config[:email_addr]} when job #{job_id} completes ...\033[0m"
	`ssh -q #{config[:ssh_nick]} "nohup #{project_dir}/txt-when-done.sh #{job_id} #{config[:email_addr]} > /dev/null 2>&1 &"`
end
#8145741144@tmomail.net



