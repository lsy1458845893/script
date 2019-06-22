

SERVICE_FILE=/etc/systemd/system/ssh-proxy.service
SERVER=reex.tk
PORT=$1

# check script params
(( $# == 1 )) || { echo "usage: $0 <server port>" > /dev/stderr && exit 1 ; }

# check is root user
(( $UID == 0 )) || { echo "retry use root permission" > /dev/stderr && exit 2 ; }

# check systemd path
[ -e `dirname $SERVICE_FILE` ] || { echo "systemd folder not find" > /dev/stderr && exit 3 ; }

# install autossh
if which autossh > /dev/null ; then
  AUTOSSH_PATH=`which autossh`
else
  if [ -e /usr/bin/apt ] ; then
    echo "install autossh"
    if apt install -y autossh > /dev/null ; then
      AUTOSSH_PATH=`which autossh`
    else
      echo "autossh install failed" > /dev/stderr
      exit 4
    fi
  else
    echo "please install autossh" > /dev/stderr
    exit 5
  fi
fi

# update ssh-proxy.service
{
  echo "[Unit]"                                                            
  echo "Description=Reserve proxy ssh -> $SERVER:$PORT"                    
  echo "After=network-online.target"                                       
  echo ""                                                                  
  echo "[Service]"                                                         
  echo "User=root"                                                         
  echo "ExecStart=$AUTOSSH_PATH -NR '*:$PORT:localhost:22' root@$SERVER" 
  echo "RestartSec=5"                                                      
  echo "Restart=always"                                                    
  echo ""                                                                  
  echo "[Install]"                                                         
  echo "WantedBy=multi-user.target"                                        
} > $SERVICE_FILE

systemctl enable $SERVICE_FILE || { echo "systemd enable failed" > /dev/stderr && exit 6 ; }
