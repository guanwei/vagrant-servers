# -*- coding: utf-8 -*-

# Usage
# test.py -d <date>
# Example: test.py -d 2017_09_23
#

import os
import sys, getopt, getpass
import subprocess

Commands = [
'mysqldump -h [host] -u [username] -p[password] --set-gtid-purged=OFF --databases fpp_client --tables weight reading_record_tbl > ~/data/fpp/db/[DATE]/dump.sql',
'mongoexport --host [host] -u [username] -p [password] -d fpp -c meal -o ~/data/fpp/db/[DATE]/mongo/meal.dat --authenticationDatabase admin',
'mongoexport --host [host] -u [username] -p [password] -d fpp -c daily_meal_log -o ~/data/fpp/db/[DATE]/mongo/daily_meal_log.dat --authenticationDatabase admin'
'mongoexport --host [host] -u [username] -p [password] -d fpp -c mom_meal_plan -o ~/data/fpp/db/[DATE]/mongo/mom_meal_plan.dat --authenticationDatabase admin',
'mongoexport --host [host] -u [username] -p [password] -d fpp -c meal_plan -o ~/data/fpp/db/[DATE]/mongo/meal_plan.dat --authenticationDatabase admin',
'mongoexport --host [host] -u [username] -p [password] -d fpp -c pa_questionnaire_user_profile -o ~/data/fpp/db/[DATE]/mongo/pa_questionnaire_user_profile.dat --authenticationDatabase admin',
'mongoexport --host [host] -u [username] -p [password] -d fpp -c pregnancy_risk_report -o ~/data/fpp/db/[DATE]/mongo/pregnancy_risk_report.dat --authenticationDatabase admin',
'mongoexport --host [host] -u [username] -p [password] -d fpp -c pregnancy_risk_result -o ~/data/fpp/db/[DATE]/mongo/pregnancy_risk_result.dat --authenticationDatabase admin',
'mongoexport --host [host] -u [username] -p [password] -d fpp -c questionnaire_user_profile -o ~/data/fpp/db/[DATE]/mongo/questionnaire_user_profile.dat --authenticationDatabase admin',
'mongoexport --host [host] -u [username] -p [password] -d fpp -c treatment_plan_profile -o ~/data/fpp/db/[DATE]/mongo/treatment_plan_profile.dat --authenticationDatabase admin'
]

target_zip = 'db_exported.zip'

def usage():
	print 'Usage example: test.py -d 2017_09_23'

def clearup():
	print 'need to do some clearnup work, but it is degerious, so far skip it'

def main(argv):
	date = ''
	target_path = ''
	try:
		opts, args = getopt.getopt(argv,"hd:")
	except getopt.GetoptError:
		usage()
		sys.exit(2)
	if len(opts) != 1:
		usage()
		sys.exit()
	for opt, arg in opts:
		if opt == '-h':
			usage()
			sys.exit()
		elif opt == '-d':
			date = arg
	#	elif opt ==  '-u':
	#		username = arg
	#	elif opt == '-p':
	#		passwd = arg
	target_path = '~/data/fpp/db/' + date
	if os.path.exists(target_path) != True:
		c = 'mkdir -p %s' %target_path
		print c
		subprocess.call(c, shell=True)
	host = str(raw_input('Host of MySql:'))
	username = raw_input('Username of MySql:')
	passwd = getpass.getpass('Password of MySql:')
	c = Commands[0]
	c = c.replace('[host]', host)
	c = c.replace('[username]', username)
	c = c.replace('[password]', passwd)
	c = c.replace('[DATE]', date)
	try:
		retcode = subprocess.call(c,shell=True)
		if retcode < 0:
        		print "Child was terminated by signal", retcode
    		elif retcode > 0:
        		print "Child returned", retcode
			return retcode
	except Exception as e:
		print e
		exit()

	host = raw_input('Host of MongoDB:')
	username = raw_input('Username of MongoDB:')
	passwd = getpass.getpass('Password of MongoDB:')
	for c in Commands[1:]:
		#print c
		c = c.replace('[host]', host)
		c = c.replace('[username]', username)
		c = c.replace('[password]', passwd)
		c = c.replace('[DATE]', date)
		print c
		try:
			subprocess.call(c,shell=True)
			if retcode < 0:
        			print "Child was terminated by signal", retcode
   	 		elif retcode > 0:
        			print "Child returned", retcode
				return retcode
		except Exception as e:
			print e
			exit()
	
	
	cmd = 'rm -rf %s' %target_zip		
	subprocess.call(cmd,shell=True)
	cmd = 'zip -rjP 4Research %s %s' %(target_zip, target_path)		
	subprocess.call(cmd,shell=True)

if __name__ == "__main__":
   main(sys.argv[1:])
