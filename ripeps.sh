#!/bin/bash

#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

#    Script by Michael Cook
#    Version: 1.4
#    Email: mcook@mackal.net
#    Website: mackal.net

#    This script makes ripping TV episodes easier from a DVD
#    while keeping them named nicely
#    Format: TV.Show.Name.S##E##.mkv

#    Requirements: lsdvd, HandBrake (0.9.5-1 from getdeb
#                                    for Ubuntu 11.04)

# Start configurations

dvdDevice="/dev/sr0" # Where your DVD Device is
videoDirectory="/home/mike/Videos/TV Shows/" # Where stuff is saved
# Various options for HandBrake
x264Opts="ref=2:bframes=2:subme=6:mixed-refs=0:weightb=0:8x8dct=0:trellis=0"
picOpts="--crop --strict-anamorphic --vfr -9 -5 -q 19"
audioOpts="-E copy:ac3"

# Good settings
#x264Opts="ref=6:b-adapt=2:bframes=6:direct=auto:me=umh:subq=9:analyse=all:trellis=2:no-fast-pskip=1:merange=24:deblock=-2,-2:rc-lookahead=50:aq-strength=1.2"

# Good Settings simCGI
#x264Opts="ref=9:b-adapt=2:bframes=7:direct=auto:me=umh:subq=9:analyse=all:trellis=2:no-fast-pskip=1:psy-rd=0.7,0:merange=24:rc-lookahead=50"

# Faster SD rips
#x264Opts="ref=5:mixed-refs=1:b-adapt=2:bframes=5:weightb=1:direct=auto:me=umh:subq=8:8x8dct=1:trellis=1:psy-rd=1,0:deblock=-2,-2:rc-lookahead=40:aq-strength=1.2:b-pyramid=1"

# End configuration

# Function to fetch how many audio tracks there are
function findAudio {
   audio=`grep -n "audio tracks" temp.txt | grep ".*: " -o | sed 's/: //'`
   sub=`grep -n "subtitle tracks" temp.txt | grep ".*: " -o | sed 's/: //'`
   audioStreams=$((sub-audio-1))
}

# Function to generate our -a string
function audioString {
   unset audioTracks
   for ((x=1; x<$1+1; x++)); do
      audioTracks="${audioTracks}${x}"
      if (( ${x}!=$1 )); then
         audioTracks="${audioTracks},"
      fi
   done
}

# Function to fetch how many subtitle tracks there are
function findSub {
   sub=`grep -n "subtitle tracks" temp.txt | grep ".*: " -o | sed 's/: //'`
   end=`grep -n "HandBrake has exited." temp.txt | grep ".*:" -o | sed 's/://'`
   subtitles=$((end-sub-1))
}

# Function to generate our -s string
function subString {
   unset subTracks
   for ((x=1; x<$1+1; x++)); do
      subTracks="${subTracks}${x}"
      if (( ${x}!=$1 )); then
         subTracks="${subTracks},"
      fi
   done
}

# Change the device to an iso or directory with VIDEO_TS
if [ -n "$1" ]; then
    dvdDevice="${1}"
fi

# Fetching some information about the DVD 
# so we can have them named correctly
echo -n "Please enter the title of the show: "
read title

echo -n "Please enter the season number: "
read season

echo -n "Please enter the number of the first episode on this disc: "
read firstEpisode
echo

# Read the titles on the DVD and prompt
# the user to input the titles they want
lsdvd ${dvdDevice}

declare -a titles
echo "Seperated by spaces"
echo -n "Please enter the titles you want to rip: "
read -a titles

# Set up some stuff for our envirnment
maxTitles=${#titles[@]}
cd "${videoDirectory}"
mkdir -p "${title}"
cd "${title}"

# Loop to encode all our crap

for ((i=0; i<$maxTitles; i++)); do
   episode=$((firstEpisode+i))
   HandBrakeCLI --scan -t ${titles[${i}]} -i ${dvdDevice} 2> temp.txt
  
   findAudio "${titles[${i}]}"
   audioString "${audioStreams}"
   findSub "${titles[${i}]}"
   subString "${subtitles}"

   options="${picOpts} ${audioOpts} -e x264 -x ${x264Opts} -a ${audioTracks} -s ${subTracks} -t ${titles[${i}]} -i ${dvdDevice} -o ${title}.S`printf "%02d" ${season}`E`printf "%02d" ${episode}`.mkv"
   echo ${options}
   HandBrakeCLI ${options}

   # Clean up
   rm temp.txt
done

