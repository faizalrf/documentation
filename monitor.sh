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
## Sep 15th 2021 Added writeLog method                   ##
## Updated by: Koushik Ramachandra<rkoushik.14@gmail.com ##
## Sept 2nd, 2022                                        ##
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

writeLog()
{
   MESSAGE=$1
   # Log output file, this path must be owned by maxscale OS user
   LOG_PATH=/var/log/maxscale/monitor.log

   # Create the missing log file! Faisal 25th July 2021
   if [ ! -f ${LOG_PATH} ]; then
      echo "$(date) | Start monitoring" > ${LOG_PATH}
   fi
   echo "$(date) | ${MESSAGE}" >> ${LOG_PATH}
}

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

if [[ ${MAX_PASSIVE} = "true" ]];
then
   writeLog "NOTIFY SCRIPT: Server is Passive, exiting"
else
   writeLog "NOTIFY SCRIPT: Server is Active"

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
      writeLog "NOTIFY SCRIPT: No change master required"
   else
      if [[ -z ${master_list} ]]
      then
         writeLog "NOTIFY SCRIPT: Master list is empty"
      else
         writeLog "Master list is not empty ${master_list}, event is ${event}"
         # When the master is lost.
         if [[ ${event} = "lost_master" ]]
         then
            writeLog "NOTIFY SCRIPT: We have lost a master (${initiator}), trying to connect and stop slave'"
            if [[ ${initiator} =~ "," ]];
            then
               writeLog "NOTIFY SCRIPT: ... more than one master in list, using first one."
               lv_initiator=`echo ${initiator} | cut -f1 -d"," | sed 's/\[//g' | sed 's/\]//g'`
            else
               writeLog "NOTIFY SCRIPT: ... there is only one master in the list."
               lv_initiator=`echo ${initiator} | sed 's/\[//g' | sed 's/\]//g'`
            fi
            lv_master_host=`echo ${lv_initiator} | cut -f1 -d":"`
            lv_master_port=`echo ${lv_initiator} | cut -f2 -d":"`
            # This may fail depending on why server went away
            TMPFILE=`mktemp`
            echo "STOP ALL SLAVES; RESET SLAVE '${Remote_MaxScale_Name}' ALL;" > ${TMPFILE}
            writeLog "STOP ALL SLAVES; RESET SLAVE '${Remote_MaxScale_Name}' ALL;"
            mariadb -u${Replication_User_Name} -p${Replication_User_Pwd} -h${lv_master_host} -P${lv_master_port} < ${TMPFILE}
            rm ${TMPFILE} # End of process lost master
         fi

         # When a new Master is selected, That new master will be used as a slave to the remote MaxScale
         if [[ ${event} = "new_master" ]]
         then
            writeLog "NOTIFY SCRIPT: Dectected a ${event} event, new master list = '${master_list}'"
            if [[ ${master_list} =~ "," ]];
            then
               writeLog "NOTIFY SCRIPT: ... more than one master in list, using first one."
               lv_master_to_use=`echo ${master_list} | cut -f1 -d"," | sed 's/\[//g' | sed 's/\]//g'`
            else
               writeLog "NOTIFY SCRIPT: ... there is only one master in the list."
               lv_master_to_use=`echo ${master_list} | sed 's/\[//g' | sed 's/\]//g'`
            fi

            lv_master_host=`echo ${lv_master_to_use} | cut -f1 -d":"`
            lv_master_port=`echo ${lv_master_to_use} | cut -f2 -d":"`

            TMPFILE=`mktemp`

            # Ensure all slaves are stopped first
            echo "STOP ALL SLAVES; RESET SLAVE '${Remote_MaxScale_Name}' ALL;" > ${TMPFILE}
            writeLog "STOP ALL SLAVES; RESET SLAVE '${Remote_MaxScale_Name}' ALL;"
            mariadb -u${Replication_User_Name} -p${Replication_User_Pwd} -h${lv_master_host} -P${lv_master_port} < ${TMPFILE}

            # Get `gtid_slave_pos` and  `gtid_binlog_pos` (ex. gtid_slave_pos='1-100-11' | gtid_binlog_pos='1-100-13','2-200-6')
            slave_pos=`mariadb -u${Replication_User_Name} -p${Replication_User_Pwd} -h${lv_master_host} -P${lv_master_port} -ss -e "select @@gtid_slave_pos"`;
            binlog_pos=`mariadb -u${Replication_User_Name} -p${Replication_User_Pwd} -h${lv_master_host} -P${lv_master_port} -ss -e "select @@gtid_binlog_pos"`;
            writeLog "GTID_SLAVE_POS = $slave_pos / GTID_BINLOG_POS = ${binlog_pos}"

            # If current 'GTID_SLAVE_POS' is not empty, assign the most up-to-date GTID_SLAVE_POS before 'CHANGE MASTER ..'
	         if [[ ${slave_pos} = "none" ]]
	         then
               writeLog "NOTIFY SCRIPT: GTID_SLAVE_POS is empty"
            else
               #Step 1: consume slave_pos and binlog_pos - let's say (1-100-11, 2-200-12, 3-300-11) and (1-100-09, 2-200-14) respectively
               #Step 2: For every Domain_id-server_id combination in slave_pos in this case, 1-100, 2-200 and 3-300 find the sequence numbers (11, 12 and 11)
               #Step 3: Compare these sequence numbers with the ones in the binlog pos against same domain and find maximum, if nothing exists, then the original one wins.
               #Step 4: Append the maximum to the Domain_id-server_id and return in this case 1-100-11,2-200-14,3-300-11
               #Step 5: Use that as the slave_pos during slave migration

               slave_pos_list=()
               for each_slave_pos in $(echo $slave_pos | sed "s/,/ /g")
               do
                  slave_pos_noseq=${each_slave_pos%-*}
                  writeLog "slave_pos_noseq = ${slave_pos_noseq}"

                  slave_pos_seq_no=${each_slave_pos##*-}
                  binlog_seq_num=`echo ${binlog_pos} | sed "s/.*${slave_pos_noseq}-//" | sed "s/\,.*//"`

                  writeLog "slave_pos_seq_no = ${slave_pos_seq_no}"
                  writeLog "binlog_seq_num = ${binlog_seq_num}"

                  gtid_seq=$(if [ "${slave_pos_seq_no}" \> "${binlog_seq_num}" ]; then echo ${slave_pos_seq_no}; else echo ${binlog_seq_num}; fi)
                  writeLog "gtid_seq = ${gtid_seq}"

                  slave_pos_list+=(`echo "${slave_pos_noseq}-${gtid_seq}"`)
               done
               printf -v joined '%s,' "${slave_pos_list[@]}"

               updated_slave_pos=`echo "${joined%,}"`

               # Set the up-to-date gtid_slave_pos by combining slave_pos_noseq + gtid_seq ("1-100" + "-" + "13")
               echo "SET GLOBAL GTID_SLAVE_POS = '${updated_slave_pos}';" > ${TMPFILE}
               writeLog "SET GLOBAL GTID_SLAVE_POS = '${updated_slave_pos}';"
               mariadb -u${Replication_User_Name} -p${Replication_User_Pwd} -h${lv_master_host} -P${lv_master_port} < ${TMPFILE}
            fi # End of slave pos none

            # If Remote MaxScale Host is defined, then execute CHANGE MASTER to connect to it on the new MASTER selection
            if [[ ${Remote_MaxScale_Host} = "none" ]]
            then
               writeLog "NOTIFY SCRIPT: No master host set for Remote_MaxScale_Host"
            else
               writeLog "NOTIFY SCRIPT: Running change master on master server ${lv_master_to_use} to ${Remote_MaxScale_Host}"
               echo "CHANGE MASTER '${Remote_MaxScale_Name}' TO MASTER_USE_GTID=slave_pos, MASTER_HOST='${Remote_MaxScale_Host}', MASTER_USER='${Replication_User_Name}', MASTER_PASSWORD='${Replication_User_Pwd}', MASTER_PORT=${Remote_MaxScale_Port}, MASTER_CONNECT_RETRY=10;" > ${TMPFILE}
               writeLog "CHANGE MASTER '${Remote_MaxScale_Name}' TO MASTER_USE_GTID=slave_pos, MASTER_HOST='${Remote_MaxScale_Host}', MASTER_USER='${Replication_User_Name}', MASTER_PASSWORD='*********************', MASTER_PORT=${Remote_MaxScale_Port}, MASTER_CONNECT_RETRY=10;"
               mariadb -u${Replication_User_Name} -p${Replication_User_Pwd} -h${lv_master_host} -P${lv_master_port} < ${TMPFILE}
               RetStatus=$?
               writeLog "CHANGE MASTER: return status ${RetStatus}"

               # Execute START SLAVE only when CHANGE MASTER is successful
               if [ ${RetStatus} -eq 0 ]; then
                  echo "START SLAVE '${Remote_MaxScale_Name}';" > ${TMPFILE}
                  writeLog "START SLAVE '${Remote_MaxScale_Name}';"
                  mariadb -u${Replication_User_Name} -p${Replication_User_Pwd} -h${lv_master_host} -P${lv_master_port} < ${TMPFILE}
               else
                  writeLog "Failed to execute CHANGE MASTER on Host: ${lv_master_host} Port: ${lv_master_port}"
               fi
            fi # End of remote maxscale host
            rm ${TMPFILE}
         fi # End of new master
      fi
   fi
fi
