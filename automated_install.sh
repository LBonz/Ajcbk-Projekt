#!/bin/bash



ProductID=YOUR_PRODUCT_ID_HERE

ClientID=YOUR_CLIENT_ID_HERE

ClientSecret=YOUR_CLIENT_SECRET_HERE

Country=''
State=''
City=''
Organization=''
DeviceSerialNumber=''
KeyStorePassword=''

 Arguments are: Yes-Enabled No-Enabled Quit-Enabled
YES_ANSWER=1
NO_ANSWER=2
QUIT_ANSWER=3
parse_user_input()
{
  if [ "$1" = "0" ] && [ "$2" = "0" ] && [ "$3" = "0" ]; then
    return
  fi
  while [ true ]; do
    Options="["
    if [ "$1" = "1" ]; then
      Options="${Options}y"
      if [ "$2" = "1" ] || [ "$3" = "1" ]; then
        Options="$Options/"
      fi
    fi
    if [ "$2" = "1" ]; then
      Options="${Options}n"
      if [ "$3" = "1" ]; then
        Options="$Options/"
      fi
    fi
    if [ "$3" = "1" ]; then
      Options="${Options}quit"
    fi
    Options="$Options]"
    read -p "$Options >> " USER_RESPONSE
    USER_RESPONSE=$(echo $USER_RESPONSE | awk '{print tolower($0)}')
    if [ "$USER_RESPONSE" = "y" ] && [ "$1" = "1" ]; then
      return $YES_ANSWER
    else
      if [ "$USER_RESPONSE" = "n" ] && [ "$2" = "1" ]; then
        return $NO_ANSWER
      else
        if [ "$USER_RESPONSE" = "quit" ] && [ "$3" = "1" ]; then
          printf "auf wieder sehen"
          exit
        fi
      fi
    fi
    printf "Please enter a valid response.\n"
  done
}


select_option()
{
  local _result=$1
  local ARGS=("$@")
  if [ "$#" -gt 0 ]; then
      while [ true ]; do
         local count=1
         for option in "${ARGS[@]:1}"; do
            echo "$count) $option"
            ((count+=1))
         done
         echo ""
         local USER_RESPONSE
         read -p "Please select an option [1-$(($#-1))] " USER_RESPONSE
         case $USER_RESPONSE in
             ''|*[!0-9]*) echo "Please provide a valid number"
                          continue
                          ;;
             *) if [[ "$USER_RESPONSE" -gt 0 && $((USER_RESPONSE+1)) -le "$#" ]]; then
                    local SELECTION=${ARGS[($USER_RESPONSE)]}
                    echo "Selection: $SELECTION"
                    eval $_result=\$SELECTION
                    return
                else
                    clear
                    echo "Please select a valid option"
                fi
                ;;
         esac
      done
  fi
}


Credential=""
get_credential()
{
  Credential=""
  read -p ">> " Credential
  while [ "${#Credential}" -lt "$1" ]; do
    echo "Input has invalid length."
    echo "Please try again."
    read -p ">> " Credential
  done
}

-----------------------------------------------------
check_credentials()
{
  clear

  echo ""
  echo ""
  if [ "${#ProductID}" -eq 0 ] || [ "${#ClientID}" -eq 0 ] || [ "${#ClientSecret}" -eq 0 ]; then

    echo ""
    parse_user_input 1 0 1
  fi

  if [ "${#ProductID}" -ge 1 ] && [ "${#ClientID}" -ge 15 ] && [ "${#ClientSecret}" -ge 15 ]; then
    echo "ProductID >> $ProductID"
    echo "ClientID >> $ClientID"
    echo "ClientSecret >> $ClientSecret"
    echo ""
    echo ""
    echo "Is this information correct?"
    echo ""
    echo ""
    parse_user_input 1 1 0
    USER_RESPONSE=$?
    if [ "$USER_RESPONSE" = "$YES_ANSWER" ]; then
      return
    fi
  fi

  clear
#produktschlüssel
  NeedUpdate=0
  echo ""
  if [ "${#ProductID}" -eq 0 ]; then
    echo "Your ProductID is not set"
    NeedUpdate=1
  else
    echo "Your ProductID is set to: $ProductID."
    echo "Is this information correct?"
    echo ""
    parse_user_input 1 1 0
    USER_RESPONSE=$?
    if [ "$USER_RESPONSE" = "$NO_ANSWER" ]; then
      NeedUpdate=1
    fi
  fi
  if [ $NeedUpdate -eq 1 ]; then
    echo ""
  
    get_credential 1
    ProductID=$Credential
  fi


  #ClientID
  NeedUpdate=0
  echo ""
  if [ "${#ClientID}" -eq 0 ]; then
    echo "Your ClientID is not set"
    NeedUpdate=1
  else
    echo "Your ClientID is set to: $ClientID."
    echo "Is this information correct?"
    echo ""
    parse_user_input 1 1 0
    USER_RESPONSE=$?
    if [ "$USER_RESPONSE" = "$NO_ANSWER" ]; then
      NeedUpdate=1
    fi
  fi
  if [ $NeedUpdate -eq 1 ]; then
    echo ""
    echo "Please enter your ClientID."
    echo "This value should match the information at https://developer.amazon.com/edw/home.html."
    echo "The information is located under the 'Security Profile' tab."
    echo "E.g.: amzn1.application-oa2-client.xxxxxxxx"
    get_credential 28
    ClientID=$Credential
  fi

  echo "-------------------------------"
  echo "ClientID is set to >> $ClientID"
  echo "-------------------------------"

  # ClientSecret
  NeedUpdate=0
  echo ""
  if [ "${#ClientSecret}" -eq 0 ]; then
    echo "Your ClientSecret is not set"
    NeedUpdate=1
  else
    echo "Your ClientSecret is set to: $ClientSecret."
    echo "Is this information correct?"
    echo ""
    parse_user_input 1 1 0
    USER_RESPONSE=$?
    if [ "$USER_RESPONSE" = "$NO_ANSWER" ]; then
      NeedUpdate=1
    fi
  fi
  if [ $NeedUpdate -eq 1 ]; then
    echo ""
    get_credential 20
    ClientSecret=$Credential
  fi

  echo "-------------------------------"
  echo "ClientSecret is set to >> $ClientSecret"
  echo "-------------------------------"

  check_credentials
}


use_template()
{
  Template_Loc=$1
  Template_Name=$2
  Target_Name=$3
  while IFS='' read -r line || [[ -n "$line" ]]; do
    while [[ "$line" =~ (\$\{[a-zA-Z_][a-zA-Z_0-9]*\}) ]]; do
      LHS=${BASH_REMATCH[1]}
      RHS="$(eval echo "\"$LHS\"")"
      line=${line//$LHS/$RHS}
    done
    echo "$line" >> "$Template_Loc/$Target_Name"
  done < "$Template_Loc/$Template_Name"
}

get_alpn_version()
{
  Java_Version=`java -version 2>&1 | awk 'NR==1{ gsub(/"/,""); print $3 }'`
  echo "java version: $Java_Version "
  Java_Major_Version=$(echo $Java_Version | cut -d '_' -f 1)
  Java_Minor_Version=$(echo $Java_Version | cut -d '_' -f 2)
  echo "major version: $Java_Major_Version minor version: $Java_Minor_Version"
  
  Alpn_Version=""
  if [ "$Java_Major_Version" = "1.8.0" ] && [ "$Java_Minor_Version" -gt 59 ]; then
    if [ "$Java_Minor_Version" -gt 120 ]; then
      Alpn_Version="8.1.11.v20170118"
    elif [ "$Java_Minor_Version" -gt 111 ]; then
      Alpn_Version="8.1.10.v20161026"
    elif [ "$Java_Minor_Version" -gt 100 ]; then
      Alpn_Version="8.1.9.v20160720"
    elif [ "$Java_Version" == "1.8.0_92" ]; then
      Alpn_Version="8.1.8.v20160420"
    elif [ "$Java_Minor_Version" -gt 70 ]; then
      Alpn_Version="8.1.7.v20160121"
    elif [[ $Java_Version ==  "1.8.0_66" ]]; then
      Alpn_Version="8.1.6.v20151105"
    elif [[ $Java_Version ==  "1.8.0_65" ]]; then
      Alpn_Version="8.1.6.v20151105"
    elif [[ $Java_Version ==  "1.8.0_60" ]]; then
      Alpn_Version="8.1.5.v20150921"
    fi
  else
    read -t 10 -p "Hit ENTER or wait ten seconds"
  fi
}



parse_user_input 1 0 1

clear

parse_user_input 1 1 1
USER_RESPONSE=$?
if [ "$USER_RESPONSE" = "$NO_ANSWER" ]; then
  clear

  parse_user_input 1 0 1
fi


if [ "$ProductID" = "YOUR_PRODUCT_ID_HERE" ]; then
  ProductID=""
fi
if [ "$ClientID" = "YOUR_CLIENT_ID_HERE" ]; then
  ClientID=""
fi
if [ "$ClientSecret" = "YOUR_CLIENT_SECRET_HERE" ]; then
  ClientSecret=""
fi

check_credentials


OS=rpi
User=$(id -un)
Group=$(id -gn)
Origin=$(pwd)
Samples_Loc=$Origin/samples
Java_Client_Loc=$Samples_Loc/javaclient
Wake_Word_Agent_Loc=$Samples_Loc/wakeWordAgent
Companion_Service_Loc=$Samples_Loc/companionService
Kitt_Ai_Loc=$Wake_Word_Agent_Loc/kitt_ai
Sensory_Loc=$Wake_Word_Agent_Loc/sensory
External_Loc=$Wake_Word_Agent_Loc/ext
Locale="en-US"

mkdir $Kitt_Ai_Loc
mkdir $Sensory_Loc
mkdir $External_Loc


# Select a Locale
clear
echo "==== Setting Locale ====="
echo ""
echo ""
echo "Which locale would you like to use?"
echo ""
echo ""
echo "======================================================="
echo ""
echo ""
select_option Locale "en-US" "en-GB" "de-DE" "en-CA" "en-IN" "ja-JP"

# Force audio to correct output
clear
echo "==== Setting Audio Output ====="
echo ""
echo ""
echo "Are you using 3.5mm jack or HDMI cable for audio output?"
echo ""
echo ""
echo "======================================================="
echo ""
echo ""
select_option audio_output "3.5mm jack" "HDMI audio output"
if [ "$audio_output" == "3.5mm jack" ]; then
  sudo amixer cset numid=3 1
  echo "Audio forced to 3.5mm jack."
else
  sudo amixer cset numid=3 2
  echo "Audio forced to HDMI."
fi

Wake_Word_Detection_Enabled="true"

clear
echo "=== Enabling Hands Free Experience using Wake Word \"Alexa\" ===="
echo ""
echo ""
echo "Do you want to enable \"Alexa\" Wake Word Detection?"
echo ""
echo ""
echo "======================================================="
echo ""
echo ""
parse_user_input 1 1 1
USER_RESPONSE=$?
if [ "$USER_RESPONSE" = "$NO_ANSWER" ]; then
  Wake_Word_Detection_Enabled="false"
fi

echo ""
echo ""
echo "==============================================="
echo " Making sure we are installing to the right OS"
echo "==============================================="
echo ""
echo ""
echo "=========== Installing Oracle Java8 ==========="
echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
chmod +x $Java_Client_Loc/install-java8.sh
cd $Java_Client_Loc && bash ./install-java8.sh
cd $Origin

# abhängigkeiten
#Aptitude
sudo apt-get update
sudo apt-get upgrade -yq

# Git 
sudo apt-get install -y git


cd $Kitt_Ai_Loc
git clone https://github.com/Kitt-AI/snowboy.git

cd $Sensory_Loc
git clone https://github.com/Sensory/alexa-rpi.git

cd $Origin


sudo apt-get -y install libasound2-dev
sudo apt-get -y install libatlas-base-dev
sudo ldconfig

sudo apt-get -y install wiringpi
sudo ldconfig

sudo apt-get install -y vlc vlc-nox vlc-data

sudo sh -c "echo \"/usr/lib/vlc\" >> /etc/ld.so.conf.d/vlc_lib.conf"
sudo sh -c "echo \"VLC_PLUGIN_PATH=\"/usr/lib/vlc/plugin\"\" >> /etc/environment"

if ! ldconfig -p | grep "libvlc.so "; then
  [ -e $Java_Client_Loc/lib ] || mkdir $Java_Client_Loc/lib
  if ! [ -e $Java_Client_Loc/lib/libvlc.so ]; then
   Target_Lib=`ldconfig -p | grep libvlc.so | sort | tail -n 1 | rev | cut -d " " -f 1 | rev`
   ln -s $Target_Lib $Java_Client_Loc/lib/libvlc.so
  fi 
fi

sudo ldconfig

#NodeJS
sudo apt-get install -y nodejs npm build-essential
sudo ln -s /usr/bin/nodejs /usr/bin/node
node -v
sudo ldconfig

# Maven 
sudo apt-get install -y maven
mvn -version
sudo ldconfig

#OpenSSL
sudo apt-get install -y openssl
sudo ldconfig

#Audio Library 
cd $Kitt_Ai_Loc/snowboy/examples/C++
bash ./install_portaudio.sh
sudo ldconfig
cd $Kitt_Ai_Loc/snowboy/examples/C++
make -j4
sudo ldconfig
cd $Origin

#ssl
if [ -f $Java_Client_Loc/ssl.cnf ]; then
  rm $Java_Client_Loc/ssl.cnf
fi
use_template $Java_Client_Loc template_ssl_cnf ssl.cnf



if [ -f $Companion_Service_Loc/config.js ]; then
  rm $Companion_Service_Loc/config.js
fi
use_template $Companion_Service_Loc template_config_js config.js

#Java client
if [ -f $Java_Client_Loc/config.json ]; then
  rm $Java_Client_Loc/config.json
fi
use_template $Java_Client_Loc template_config_json config.json

#Alsa
if [ -f /home/$User/.asoundrc ]; then
  rm /home/$User/.asoundrc
fi
printf "pcm.!default {\n  type asym\n   playback.pcm {\n     type plug\n     slave.pcm \"hw:0,0\"\n   }\n   capture.pcm {\n     type plug\n     slave.pcm \"hw:1,0\"\n   }\n}" >> /home/$User/.asoundrc

 #CMake
sudo apt-get install -y cmake
sudo ldconfig

#Java Client
if [ -f $Java_Client_Loc/pom.xml ]; then
  rm $Java_Client_Loc/pom.xml
fi

get_alpn_version

cp $Java_Client_Loc/pom_pi.xml $Java_Client_Loc/pom.xml


cd $Java_Client_Loc && mvn validate && mvn install && cd $Origin

cd $Companion_Service_Loc && npm install && cd $Origin

if [ "$Wake_Word_Detection_Enabled" = "true" ]; then
  
  mkdir $External_Loc/include
  mkdir $External_Loc/lib
  mkdir $External_Loc/resources

  cp $Kitt_Ai_Loc/snowboy/include/snowboy-detect.h $External_Loc/include/snowboy-detect.h
  cp $Kitt_Ai_Loc/snowboy/examples/C++/portaudio/install/include/portaudio.h $External_Loc/include/portaudio.h
  cp $Kitt_Ai_Loc/snowboy/examples/C++/portaudio/install/include/pa_ringbuffer.h $External_Loc/include/pa_ringbuffer.h
  cp $Kitt_Ai_Loc/snowboy/examples/C++/portaudio/install/include/pa_util.h $External_Loc/include/pa_util.h
  cp $Kitt_Ai_Loc/snowboy/lib/$OS/libsnowboy-detect.a $External_Loc/lib/libsnowboy-detect.a
  cp $Kitt_Ai_Loc/snowboy/examples/C++/portaudio/install/lib/libportaudio.a $External_Loc/lib/libportaudio.a
  cp $Kitt_Ai_Loc/snowboy/resources/common.res $External_Loc/resources/common.res

  sudo ln -s /usr/lib/atlas-base/atlas/libblas.so.3 $External_Loc/lib/libblas.so.3

 
  mkdir $Wake_Word_Agent_Loc/tst/ext
  cp -R $External_Loc/* $Wake_Word_Agent_Loc/tst/ext
  cd $Origin

  echo 
  cd $Wake_Word_Agent_Loc/src && cmake . && make -j4
  cd $Wake_Word_Agent_Loc/tst && cmake . && make -j4
fi

chown -R $User:$Group $Origin
chown -R $User:$Group /home/$User/.asoundrc

cd $Origin


Number_Terminals=2
if [ "$Wake_Word_Detection_Enabled" = "true" ]; then
  Number_Terminals=3
fi

if [ "$Wake_Word_Detection_Enabled" = "true" ]; then
  echo "Run the wake word agent: "

