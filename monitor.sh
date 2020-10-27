#!/bin/bash

###################################################
## MaxScale Notify Script                        ##
## Kester Riley <kester.riley@mariadb.com>       ##
## March 2020                                    ##
## Updated by: Faisal Saeed <faisal@mariadb.com> ##
## October 26th 2020                             ##
###################################################

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE
# AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

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

if [[ $MAX_PASSIVE = "true" ]];
then
   echo "NOTIFY SCRIPT: Server is Passive, exiting" >> /tmp/notify.log
else
  echo "NOTIFY SCRIPT: Server is Active" >> /tmp/notify.log

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

  #This needs to point to the remove MaxScale on the opposite DC
  Remote_MaxScale_Host="172.31.28.176"
  Remote_MaxScale_Name="DR-RemoteMaxScale"
  
  #Read the arguments passed in by MaxScale
  process_arguments $@

  if [[ $Remote_MaxScale_Host = "none" ]]
  then
     echo "NOTIFY SCRIPT: No change master required" >> /tmp/notify.log
  else
    if [[ -z $master_list ]]
    then
       echo "NOTIFY SCRIPT: Master list is empty" >> /tmp/notify.log
    else
      echo "master list is not empty $master_list, event is $event" >> /tmp/notify.log
      if [[ $event = "lost_master" ]]
      then
        echo "NOTIFY SCRIPT: We have lost a master ($initiator), trying to connect and stop slave'" >> /tmp/notify.log
        if [[ $initiator =~ "," ]];
        then
           echo "NOTIFY SCRIPT: ... more than one master in list, using first one." >> /tmp/notify.log
           lv_initiator=`echo $initiator | cut -f1 -d"," | sed 's/\[//g' | sed 's/\]//g'`
        else
           echo "NOTIFY SCRIPT: ... there is only one master in the list." >> /tmp/notify.log
           lv_initiator=`echo $initiator | sed 's/\[//g' | sed 's/\]//g'`
        fi
        lv_master_host=`echo $lv_initiator | cut -f1 -d":"`
        lv_master_port=`echo $lv_initiator | cut -f2 -d":"`
        # This may fail depending on why server went away
        TMPFILE=`mktemp`
        echo "STOP ALL SLAVES; RESET SLAVE ALL;" > $TMPFILE
        echo "STOP ALL SLAVES; RESET SLAVE ALL;" >> /tmp/notify.log
        mariadb -urepl_user -pSecretP@ssw0rd -h$lv_master_host -P$lv_master_port < $TMPFILE
        rm $TMPFILE
      fi


      if [[ $event = "new_master" ]]
      then
        echo "NOTIFY SCRIPT: Dectected a new master event, new master list = '$master_list'" >> /tmp/notify.log
        if [[ $master_list =~ "," ]];
        then
           echo "NOTIFY SCRIPT: ... more than one master in list, using first one." >> /tmp/notify.log
           lv_master_to_use=`echo $master_list | cut -f1 -d"," | sed 's/\[//g' | sed 's/\]//g'`
        else
           echo "NOTIFY SCRIPT: ... there is only one master in the list." >> /tmp/notify.log
           lv_master_to_use=`echo $master_list | sed 's/\[//g' | sed 's/\]//g'`
        fi
        lv_master_host=`echo $lv_master_to_use | cut -f1 -d":"`
        lv_master_port=`echo $lv_master_to_use | cut -f2 -d":"`

        TMPFILE=`mktemp`

        #Ensure all slaves are stopped first
        echo "STOP ALL SLAVES; RESET SLAVE ALL;" > $TMPFILE
        echo "STOP ALL SLAVES; RESET SLAVE ALL;" >> /tmp/notify.log
        mariadb -urepl_user -pSecretP@ssw0rd -h$lv_master_host -P$lv_master_port < $TMPFILE

        if [[ $Remote_MaxScale_Host = "none" ]]
        then
           echo "NOTIFY SCRIPT: No master host set for Remote_MaxScale_Host" >> /tmp/notify.log
        else
           echo "NOTIFY SCRIPT: Running change master on master server $lv_master_to_use to $Remote_MaxScale_Host" >> /tmp/notify.log
           echo "CHANGE MASTER '${Remote_MaxScale_Name}' TO master_use_gtid = slave_pos, MASTER_HOST='$Remote_MaxScale_Host', MASTER_USER='repl_user', MASTER_PASSWORD='SecretP@ssw0rd', MASTER_PORT=4007, MASTER_CONNECT_RETRY=10; " > $TMPFILE
           echo "CHANGE MASTER '${Remote_MaxScale_Name}' TO master_use_gtid = slave_pos, MASTER_HOST='$Remote_MaxScale_Host', MASTER_USER='repl_user', MASTER_PASSWORD='SecretP@ssw0rd', MASTER_PORT=4007, MASTER_CONNECT_RETRY=10; "  >> /tmp/notify.log
           mariadb -urepl_user -pSecretP@ssw0rd -h$lv_master_host -P$lv_master_port < $TMPFILE
           echo "return status $?" >> /tmp/notify.log
           echo "START SLAVE '${Remote_MaxScale_Name}';" > $TMPFILE
           mariadb -urepl_user -pSecretP@ssw0rd -h$lv_master_host -P$lv_master_port < $TMPFILE
        fi
        rm $TMPFILE
      fi
    fi
  fi
fi
