#!/bin/bash

function fatal()
{
	echo $@ >&2

	if [ -f /tmp/leech_err ]; then
		echo -e "\nOUTPUT:\n"
		cat /tmp/leech_err
	fi

	exit 1
}

rm -f /tmp/leech_err

if [ -z "$1" ]; then
	fatal usage: $(basename $0) [device uuid]
fi

if [ ! -f diagnose.sh ]; then
	fatal Missing diagnose.sh file.
fi

uuid=$1

# Gets current script dir, see http://stackoverflow.com/a/246128.
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
out_dir=${script_dir}/out
out_file=${uuid}_$(date +%Y%m%d%H%M).txt
output=${out_dir}/${out_file}

mkdir -p ${out_dir}

ssh_opts="-o Hostname=$uuid.vpn -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"

echo Copying script to device...
scp -q -p $ssh_opts ${script_dir}/diagnose.sh resin:/home/root/ 2>/tmp/leech_err
[ "$?" != 0 ] && fatal "ERROR: Script copy failed."

echo Executing script...
ssh $ssh_opts resin "bash /home/root/diagnose.sh" >$output 2>/tmp/leech_err
[ "$?" != 0 ] && fatal "ERROR: Script execution failed."

echo Done! Output stored in $out_file
