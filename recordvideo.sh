#!/bin/bash

# VidREs
#sqcif=128x96, qcif=176x144, cif=352x288, 4cif=704x576, 16cif=1408x1152, qqvga=160x120, qvga=320x240, vga=640x480, svga=800x600, xga=1024x768, uxga=1600x1200, qxga=2048x1536, sxga=1280x1024, qsxga=2560x2048, hsxga=5120x4096, wvga=852x480, wxga=1366x768, wsxga=1600x1024, wuxga=1920x1200, oxga=2560x1600, wqsxga=3200x2048, wquxga=3840x2400, whsxga=6400x4096, whuxga=7680x4800, cga=320x200, ega=640x350, hd480=852x480, hd720=1280x720, hd1080=1920x1080
# or custom resolution

#Input Device
# alsa, bktr, dv1394, fbdev, jack, libdc1394, oss, sndio, video4linux, vfwcap, x11grab

DESKFILE=":0.0"
CAMFILE=/dev/video0

AUDFILE="pch"
#AUDFILE="/dev/snd/pcmC1D3p"
#MICFILE=/dev/dsp
MICFILE="hw:0"

SNDINPUTDEV=alsa
#SNDINPUTDEV=pulse
#SNDINPUTDEV=oss

AUDTYPE=ogg
VIDTYPE=webm

FRAMERATE=24

STARTRECORD() {

  # Build the video options
  case "$VIDSRC" in 
  "desktop" )
    VIDINPUTDEV=x11grab
    #VIDRES=$(xrandr|grep "*"|tr -s " "|cut -d " " -f 2)
    VIDRES=$(xwininfo -root | grep 'geometry' | awk '{print $2;}'|cut -d "+" -f 1)
    VIDINPUTFILE=$DESKFILE

    VIDOPTS="-f $VIDINPUTDEV -s $VIDRES -r $FRAMERATE -i $VIDINPUTFILE"
    ;;
  "webcam" )
    VIDINPUTDEV=video4linux2
    #VIDINPUTDEV=v4l2-ctl
    VIDRES=$(for i in `lsusb -v|grep wWidth|tr -s " "|cut -d " " -f 3`; do b=$(printf %04d ${i%});echo $b;done|sort|tail -n 1)x$(for i in `lsusb -v|grep wHeight|tr -s " "|cut -d " " -f 3`; do b=$(printf %04d ${i%});echo $b;done|sort|tail -n 1)
    VIDINPUTFILE=$CAMFILE

    VIDOPTS="-f $VIDINPUTDEV -s $VIDRES -r $FRAMERATE -i $VIDINPUTFILE"
    ;;
  "none" )
    VIDOPTS=""
    ;;
  * )
    printf "\n invalid video input"
    HELPOUTPUT
    exit 1
    ;;
  esac

  if [ ! "$VIDOPTS" = "" ];then
    VIDOPTS="$VIDOPTS -b 2M -bt 4M"
    VIDCOD="-vcodec libvpx"
  fi

#-threads 0 
#-vpre lossless_ultrafast 

  # Build the audio options
  case "$AUDSRC" in 
  "speaker" )
    AUDOPTS="-f $SNDINPUTDEV -i $AUDFILE"
    ;;
  "mic" )
    AUDOPTS="-f $SNDINPUTDEV -i $MICFILE"
    ;;
  "none" )
    AUDOPTS=""
    ;;
  * )
    printf "\n invalid audio input"
    HELPOUTPUT
    ;;
  esac

  if [ ! "$AUDOPTS" = "" ]; then
    AUDOPTS="$AUDOPTS -acodec pcm_s16le"
    AUDCOD="-acodec libvorbis -ac 2 -ar 48000 -ab 128k"
  fi

  if [ "$VIDSRC" = "none" -a "$AUDSRC" = "none" ]; then
    printf "\n no audio or video input was selected"
    HELPOUTPUT
  elif  [ ! "$VIDSRC" = "none" ]; then
    OUTFORMAT=$VIDTYPE
  elif  [ ! "$AUDSRC" = "none" ]; then
    OUTFORMAT=$AUDTYPE
  fi

COMD="ffmpeg $VIDOPTS $AUDOPTS $VIDCOD $AUDCOD -y $OUTFILE.$OUTFORMAT" 
#COMD="ffmpeg $VIDOPTS $AUDOPTS -vcodec libx264 -pass 2 -vpre hq -acodec libfaac -ac 2 -ar 48000 -ab 192k -y $OUTFILE.$OUTFORMAT" 
$COMD
echo "$COMD"
exit 0
#-vcodec libx264 
}

HELPOUTPUT() {
  printf "\nInvalid arguments, the proper syntax is recordvideo {video source} {audiosource} {outputfile}"
  printf "\n\t Valid video sources are desktop, webcam and none"
  printf "\n\t Valid audio sources are speaker, mic and none"
  printf "\n\t The output file should be entered without an extension\n\n"
  exit 1
}

if [ $# -eq 3 ]; then

  VIDSRC=$1
  AUDSRC=$2
  OUTFILE=$3
  
  STARTRECORD

else

  HELPOUTPUT

fi