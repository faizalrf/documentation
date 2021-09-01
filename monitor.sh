#!/bin/bash

###########################################################
## MaxScale Notify Script                                ##
## Kester Riley <kester.riley@mariadb.com>               ##
## March 2020                                            ##
## Updated by: Faisal Saeed <faisal@mariadb.com>         ##
## October 27th 2020                                     ##
## Updated by: Kwangbock Lee <kwangbock.lee@mariadb.com> ##
## December 2th 2020                                     ##
## Update by: Faisal Saeed <faisal@mariadb.com           ##
## March 1st 2021                                        ##
## Update by: Faisal Saeed <faisal@mariadb.com           ##
## July 09th 2021                                        ##
## July 25th 2021                                        ##
###########################################################

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE
# AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# Create a hidden file /var/lib/maxscale/.maxinfo and add the following 6 variables

# remoteMaxScale=<Remote MaxSclae IP>
# remoteMaxScaleName=<User Defined MaxScale Name>
# repuser=<Replication User Name>
# reppwd=<Replication User Password>
# remoteMaxScaleReplicationPort=<MaxScale Replicaton Port>
# maxuser=<MaxScale User Name>
# maxpwd=<MaxScale User Password>

# Set ownership if this file to maxuser:maxuser
#  chown maxscale:maxscale /var/lib/maxscale/.maxinfo
# set permission to be read only for maxuser and no permission for any other user
#  chmod 400 /var/lib/maxscale/.maxinfo
# End...

process_arguments()
{
   while [ "$1" != "" ]; do
      if [[ "$1" =~ ^--initiator=.* ]]; then
         initiator=${1#'--initiator='}
      elif [[ "$1" =~ ^--parent.* ]]; then
         parent=${1#'--parent='}
      elif [[ "$1" =~ ^--children.* ]]; then
         children=${1#'--children='}
      elif [[ "$1" =~ ^--event.* ]]; then
         event=${1#'--event='}
      elif [[ "$1" =~ ^--node_list.* ]]; then
         node_list=${1#'--node_list='}
      elif [[ "$1" =~ ^--list.* ]]; then
         list=${1#'--list='}
      elif [[ "$1" =~ ^--master_list.* ]]; then
         master_list=${1#'--master_list='}
      elif [[ "$1" =~ ^--slave_list.* ]]; then
         slave_list=${1#'--slave_list='}
      elif [[ "$1" =~ ^--synced_list.* ]]; then
         synced_list=${1#'--synced_list='}
      fi
      shift
   done
}

# Import info file
. /var/lib/maxscale/.maxinfo

# Log output file, this path must be owned by maxscale OS user
Log_Path=/var/lib/maxscale/monitor.log

# Create the missing log file! Faisal 25th July 2021
if [ ! -f ${Log_Path} ]; then
   touch ${Log_Path}
   echo "$(date) | Start monitoring" > ${Log_Path}
fi

if [[ ${MAX_PASSIVE} = "true" ]];
then
   echo "$(date) | NOTIFY SCRIPT: Server is Passive, exiting" >> ${Log_Path}
else
  echo "$(date) | NOTIFY SCRIPT: Server is Active" >> ${Log_Path}

  # Initialize the variables
  initiator=""
  parent=""
  children=""
  event=""
  node_list=""
  list=""
  master_list=""
  slave_list=""
  synced_list=""
  RetStatus=0

  ############################################# -Utility Methods- ##################################################
  #Finds the maximum number given the series of numbers
  function max_number() {
      printf "%s\n" "$@" | sort -g | tail -n1
  }

  #Takes in a single slave_pos 1-100-11 and compares with the list of gtid_binlog_pos (1-100-09,2-200-22), finds the match Domain_id - server_id
  #(1-100) and finds out the maximum between seq_num 11,09 in this case and returns the 1-100-11, if found nothing returns original value
  function compare_compute_gtid_slave_pos(){
      single_value_slave_pos=`echo ${1} | cut -d- -f1 -f2`
      gtid_binlog_pos="${2}"
      for i in $(echo $gtid_binlog_pos | sed "s/,/ /g")
      do
        prefix=`echo "$i" | cut -d- -f1 -f2`
        if [ "${single_value_slave_pos}" == "${prefix}" ];
        then
          slave_pos_seq_num=`echo ${1} | sed 's/.*-//'`
          gtid_binlog_pos_seq_num=`echo ${i} | sed 's/.*-//'`
          max="$(max_number $slave_pos_seq_num $gtid_binlog_pos_seq_num)"
          echo "${single_value_slave_pos}-${max}"
          return
        fi
      done

      echo ${1}
  }


  #Takes the slave_pos and gtid_binlog_pos and computes the get_gtid_slave_pos
  function get_gtid_slave_pos(){
      slave_pos="${1}" # $1 represent first argument
      gtid_binlog_pos="${2}" # $2 represent second argument
      gtid_slave_pos_list=()
      #slave_pos_noseq=`echo ${slave_pos} | awk -F, '{for (i=1;i<=NF;i++)print $i}'`
      for i in $(echo $slave_pos | sed "s/,/ /g")
      do
        # call your procedure/other scripts here below
        updated_gtid_pos="$(compare_compute_gtid_slave_pos $i $gtid_binlog_pos)"
        gtid_slave_pos_list+=(`echo "${updated_gtid_pos}"`)
      done
      printf -v joined '%s,' "${gtid_slave_pos_list[@]}"
      echo "${joined%,}"
  }

  ############################################# -End Utility Methods- ##################################################

  ############################################# -User Config- ##################################################
  #This needs to point to the remove MaxScale on the opposite DC
  Remote_MaxScale_Host=${remoteMaxScale}
  # For Instance: DR-RemoteMaxScale or DC-RemoteMaxScale
  Remote_MaxScale_Name=${remoteMaxScaleName}
  # Port of the ReadConRoute Listener port, recommended to use instead of Read/WriteSplit Setvice
  Remote_MaxScale_Port=${remoteMaxScaleReplicationPort}
  # Replication User name use in Setting up the CHANGE MASTER, GRANT REPLICATION SLAVE, REPLICATION SLAVE ADMIN ON *.* TO repl_user@'%';
  Replication_User_Name=${repuser}
  # Password for the Replication User
  Replication_User_Pwd=${reppwd}
  # MaxScale User name use who is re-configuring replication setup by executing "RESET SLAVE, CHANGE MASTER"
  MaxScale_User_Name=${maxuser}
  # Password for the MaxScale User
  MaxScale_User_Pwd=${maxpwd}
  ########################################## -User Config End- #################################################

  #Read the arguments passed in by MaxScale
  process_arguments $@

  if [[ ${Remote_MaxScale_Host} = "none" ]]
  then
     echo "$(date) | NOTIFY SCRIPT: No change master required" >> ${Log_Path}
  else
    if [[ -z ${master_list} ]]
    then
       echo "$(date) | NOTIFY SCRIPT: Master list is empty" >> ${Log_Path}
    else
      echo "$(date) | master list is not empty ${master_list}, event is ${event}" >> ${Log_Path}
      if [[ ${event} = "lost_master" ]]
      then
        echo "$(date) | NOTIFY SCRIPT: We have lost a master (${initiator}), trying to connect and stop slave'" >> ${Log_Path}
        if [[ ${initiator} =~ "," ]];
        then
           echo "$(date) | NOTIFY SCRIPT: ... more than one master in list, using first one." >> ${Log_Path}
           lv_initiator=`echo ${initiator} | cut -f1 -d"," | sed 's/\[//g' | sed 's/\]//g'`
        else
           echo "$(date) | NOTIFY SCRIPT: ... there is only one master in the list." >> ${Log_Path}
           lv_initiator=`echo ${initiator} | sed 's/\[//g' | sed 's/\]//g'`
        fi
        lv_master_host=`echo ${lv_initiator} | cut -f1 -d":"`
        lv_master_port=`echo ${lv_initiator} | cut -f2 -d":"`
        # This may fail depending on why server went away
        TMPFILE=`mktemp`
        echo "STOP ALL SLAVES; RESET SLAVE '${Remote_MaxScale_Name}' ALL;" > ${TMPFILE}
        echo "$(date) | STOP ALL SLAVES; RESET SLAVE '${Remote_MaxScale_Name}' ALL;" >> ${Log_Path}
        mariadb -u${Replication_User_Name} -p${Replication_User_Pwd} -h${lv_master_host} -P${lv_master_port} < ${TMPFILE}
        rm ${TMPFILE}
      fi

      # When a new Master is selected, That new master will be used as a slave to the remote MaxScale
      if [[ ${event} = "new_master" ]]
      then
        echo "$(date) | NOTIFY SCRIPT: Dectected a ${event} event, new master list = '${master_list}'" >> ${Log_Path}
        if [[ ${master_list} =~ "," ]];
        then
           echo "$(date) | NOTIFY SCRIPT: ... more than one master in list, using first one." >> ${Log_Path}
           lv_master_to_use=`echo ${master_list} | cut -f1 -d"," | sed 's/\[//g' | sed 's/\]//g'`
        else
           echo "$(date) | NOTIFY SCRIPT: ... there is only one master in the list." >> ${Log_Path}
           lv_master_to_use=`echo ${master_list} | sed 's/\[//g' | sed 's/\]//g'`
        fi
        lv_master_host=`echo ${lv_master_to_use} | cut -f1 -d":"`
        lv_master_port=`echo ${lv_master_to_use} | cut -f2 -d":"`

        TMPFILE=`mktemp`

        # Ensure all slaves are stopped first
        echo "STOP ALL SLAVES; RESET SLAVE '${Remote_MaxScale_Name}' ALL;" > ${TMPFILE}
        echo "$(date) | STOP ALL SLAVES; RESET SLAVE '${Remote_MaxScale_Name}' ALL;" >> ${Log_Path}
        mariadb -u${Replication_User_Name} -p${Replication_User_Pwd} -h${lv_master_host} -P${lv_master_port} < ${TMPFILE}

        # Get `gtid_slave_pos` and  `gtid_binlog_pos` (ex. gtid_slave_pos='1-100-11' | gtid_binlog_pos='1-100-13','2-200-6')
        slave_pos=`mariadb -u${Replication_User_Name} -p${Replication_User_Pwd} -h${lv_master_host} -P${lv_master_port} -ss -e "select @@gtid_slave_pos"`;
        binlog_pos=`mariadb -u${Replication_User_Name} -p${Replication_User_Pwd} -h${lv_master_host} -P${lv_master_port} -ss -e "select @@gtid_binlog_pos"`;
        echo "$(date) | gtid_slave_pos = $slave_pos / gtid_binlog_pos = ${binlog_pos}" >> ${Log_Path}

	# If current 'gtid_slave_pos' is not empty, assign the most up-to-date gtid_slave_pos before 'CHANGE MASTER ..'
	if [[ ${slave_pos} = "none" ]]
	then
	   echo "$(date) | NOTIFY SCRIPT: gtid_slave_pos is empty" >> ${Log_Path}
	else
	   # Get 'Domain_id'-'server_id' from gtid_slave_pos (ex. '1-100-11' -> '1-100') 25th Jul 2021
     updated_slave_pos="$(get_gtid_slave_pos $slave_pos $binlog_pos)"
	   echo "$(date) | updated_slave_pos = ${updated_slave_pos}" >> ${Log_Path}

	   # Set the up-to-date gtid_slave_pos by combining slave_pos_noseq + gtid_seq ("1-100" + "-" + "13")
           echo "SET GLOBAL gtid_slave_pos = '${updated_slave_pos}';" > ${TMPFILE}
           echo "$(date) | SET GLOBAL gtid_slave_pos = '${updated_slave_pos}';" >> ${Log_Path}
           mariadb -u${Replication_User_Name} -p${Replication_User_Pwd} -h${lv_master_host} -P${lv_master_port} < ${TMPFILE}
	fi
        # If Remote MaxScale Host is defined, then execute CHANGE MASTER to connect to it on the new MASTER selection
        if [[ ${Remote_MaxScale_Host} = "none" ]]
        then
           echo "$(date) | NOTIFY SCRIPT: No master host set for Remote_MaxScale_Host" >> ${Log_Path}
        else
           echo "$(date) | NOTIFY SCRIPT: Running change master on master server ${lv_master_to_use} to ${Remote_MaxScale_Host}" >> ${Log_Path}
           echo "CHANGE MASTER '${Remote_MaxScale_Name}' TO master_use_gtid=slave_pos, MASTER_HOST='${Remote_MaxScale_Host}', MASTER_USER='${Replication_User_Name}', MASTER_PASSWORD='${Replication_User_Pwd}', MASTER_PORT=${Remote_MaxScale_Port}, MASTER_CONNECT_RETRY=10; " > ${TMPFILE}
           echo "$(date) | CHANGE MASTER '${Remote_MaxScale_Name}' TO master_use_gtid=slave_pos, MASTER_HOST='${Remote_MaxScale_Host}', MASTER_USER='${Replication_User_Name}', MASTER_PASSWORD='*********************', MASTER_PORT=${Remote_MaxScale_Port}, MASTER_CONNECT_RETRY=10; "  >> ${Log_Path}
           mariadb -u${Replication_User_Name} -p${Replication_User_Pwd} -h${lv_master_host} -P${lv_master_port} < ${TMPFILE}
           RetStatus=$?
           echo "$(date) | CHANGE MASTER: return status ${RetStatus}" >> ${Log_Path}
           # Execute START SLAVE only when CHANGE MASTER is successful
           if [ ${RetStatus} -eq 0 ]
           then
              echo "START SLAVE '${Remote_MaxScale_Name}';" > ${TMPFILE}
              echo "$(date) | START SLAVE '${Remote_MaxScale_Name}';" >> ${Log_Path}
              mariadb -u${Replication_User_Name} -p${Replication_User_Pwd} -h${lv_master_host} -P${lv_master_port} < ${TMPFILE}
           else
              echo "$(date) | Failed to execute CHANGE MASTER on Host: ${lv_master_host} Port: ${lv_master_port}" >> ${Log_Path}
           fi
        fi
        rm ${TMPFILE}
      fi
    fi
  fi
fi
