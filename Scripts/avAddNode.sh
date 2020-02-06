#!/bin/bash
#
#Needed for ssh
#sudo apt install sshpass
usage()
{
echo "Usage: ${0} -s hostname -p password [-h]"
cat <<-EOF
                        -s: hostname        - Host name.
                        -p: passord         - Password.
                        -h: Help            - Help

EOF
exit 1
}
export AV_HOST=""
export AV_PASS=""
while getopts "s:p:h" i
    do
     case "$i" in
             s)
                     export AV_HOST=${OPTARG}
                     ;;

             p)
                     export AV_PASS="${OPTARG}"

        ;;
             *)
                     usage
                     exit -1
                     ;;
     esac
    done
#
# Check args
#
if [ "${AV_HOST}" == "" ]
    then
        echo "${0}: Error, you need to speciify a host."
        usage
fi

if [ "${AV_PASS}" = "" ]
    then
        echo "${0}: Error, you need to speciify a password."
        usage
fi

#
# Global ENV Variables
#
if [ -f ./avENV.sh ]
then
        . ./avENV.sh
else
        echo "Missing the 'avENV.sh' program."
        exit -1
fi
echo $AV_HOST >> /opt/Actian/VectorVH/ingres/files/hdfs/slaves
AV_STAT="`ingstatus | head -1 | awk '{print $9}'`"
if [ "${AV_STAT}" = "running" ]
    then
        echo "Please stop the VectorH instance"
        exit 1
fi
AV_SSHPASS=`which sshpass 2>&1 |  awk '{print $2}'`
if [ "${AV_SSHPASS}" = "no" ]
    then
        echo "Please install sshpass"
        
        exit 1
fi
export SSHPASS=$AV_PASS
AV_PING=`sshpass -e ssh  -o StrictHostKeyChecking=no $AV_HOST sudo touch /tmp/m 2>&1 | tail -1 | awk '{print $1}'`
echo
echo $AV_PING
echo $AV_PASS
echo $AV_HOST
if [ "${AV_PING}" = "Permission" ]
    then
        echo "Invalid password"
        exit 1
fi
if [ "${AV_PING}" = "ssh:" ]
    then
        echo "Invalid Host name"
        exit 1
fi
sshpass -e ssh  -o StrictHostKeyChecking=no $AV_HOST sudo mkdir /opt/Actian
sshpass -e ssh  -o StrictHostKeyChecking=no $AV_HOST sudo mkdir /opt/Actian/VectorVH
sshpass -e ssh  -o StrictHostKeyChecking=no $AV_HOST sudo chown actian /opt/Actian/VectorVH
#
sshpass -e iisuhdfs datanodes
ingstart
