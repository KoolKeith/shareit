#!/bin/bash

function print_help() {
  echo -en >&2 "Usage: $0 [option(s)] file1 [file2] [file...]\n-z Create a zip archive for file(s).\n-n Do not image_optimize file(s).\n-m Preserve metadata.\n-c Do not convert file(s).\n-r Do not resize the image(s) if larger than ${DEF_IMGMAXSIZE}.\n-d Print debug messages (set -x).\n-l Print the last ${DEF_LISTHISTNO} shared files.\n"
}

if [ "${1}" == "" ]; then
  print_help
  exit 255
fi

_CONFIG=~/.config/shareit.conf

if [ -f "${_CONFIG}" ]; then
  source "${_CONFIG}"
else
  echo -e "No configuration file found at \"${_CONFIG}\"\nExit..."
  exit 255
fi

[ "${DEF_DEBUG}" == "true" ] && set -x

function image_convert_raw_to_jpg() {
  # ARG1: file to convert
  # ARG2: converted file
  #_converted_file="$(mktemp -u).jpg"
  echo "INFO: Converting a RAW image into jpg..."
  dcraw -c -e "${1}" | cat > "${2}"
}

function image_resize() {
  convert "${1}" -resize "${DEF_IMGMAXSIZE}"\> "${2}" 2>/dev/null
}

function image_remove_metadata() {
  exiv2 rm "${1}"
}

function image_optimize() {
  local _file="${1}"
  local _suffix="${2}"

  case $_suffix in
    png)
      optipng "${_file}"
      ;;
    jpg)
      jpegoptim "${_file}"
      ;;
  esac
}

# function identify_filetype() {
#   local _suffix="${1/*.}"
# }

#########################
##### getopts ... #######
#########################
while getopts zncrmhld arg
do
  case "$arg" in
    z)
      DEF_CREATEZIP="true"
    ;;
    n)
      DEF_DOOPTIMIZE="false"
    ;;
    c)
      DEF_DOCONVERT="false"
    ;;
    r)
      DEF_DORESIZE="false"
    ;;
    m)
      DEF_REMOVEMETADATA="false"
    ;;
    l)
      echo "The last ${DEF_LISTHISTNO} shared files were:"
      tail -n "${DEF_LISTHISTNO}" "${_history_file}"
      exit 250
      ;;
    d)
      set -x
    ;;
    h)
      print_help
      exit 1
    ;;
  esac
done
shift $((OPTIND-1))
# No opts/args anymore; only files ...

#########################
####### Main ... ########
#########################
_tmp_dir=$(mktemp -d "/tmp/shareit.XXXXXX")

_counter=0
while [ $# -ne 0 ]; do
  _counter=$((_counter+1))
  _originalfile="${1}"
  if [[ ! -f "${_originalfile}" ]]; then
    echo "ERROR: File \"${_originalfile}\" does not exist, ignoring this one."
    shift
    continue
  fi

  # Default do's for file handling...
  DO_OPTIMIZE="false"
  DO_RESIZE="false"
  DO_REMOVEMETADATA="false"
  DO_CONVERT="false"

  _suffix="${1/*.}"
  case $_suffix in
    arw|ARW)
      [ "${DEF_DOOPTIMIZE}" == "true" ] && DO_OPTIMIZE="true"
      [ "${DEF_DORESIZE}" == "true" ] && DO_RESIZE="true"
      [ "${DEF_REMOVEMETADATA}" == "true" ] && DO_REMOVEMETADATA="true"
      [ "${DEF_DOCONVERT}" == "true" ] && DO_CONVERT="true"
    ;;
    cr2|CR2)
      [ "${DEF_DOOPTIMIZE}" == "true" ] && DO_OPTIMIZE="true"
      [ "${DEF_DORESIZE}" == "true" ] && DO_RESIZE="true"
      [ "${DEF_REMOVEMETADATA}" == "true" ] && DO_REMOVEMETADATA="true"
      [ "${DEF_DOCONVERT}" == "true" ] && DO_CONVERT="true"
    ;;
    jpg|jpeg|JPG|JPEG)
      [ "${DEF_DOOPTIMIZE}" == "true" ] && DO_OPTIMIZE="true"
      [ "${DEF_DORESIZE}" == "true" ] && DO_RESIZE="true"
      [ "${DEF_REMOVEMETADATA}" == "true" ] && DO_REMOVEMETADATA="true"
      DO_CONVERT="false"
    ;;
    png)
      [ "${DEF_DOOPTIMIZE}" == "true" ] && DO_OPTIMIZE="true"
      [ "${DEF_DORESIZE}" == "true" ] && DO_RESIZE="true"
      [ "${DEF_REMOVEMETADATA}" == "true" ] && DO_REMOVEMETADATA="true"
      DO_CONVERT="false"
    ;;
    *)
      DO_OPTIMIZE="false"
      DO_RESIZE="false"
      DO_REMOVEMETADATA="false"
      DO_CONVERT="false"
    ;;
  esac

  # Do the work now :)
  _tmp_file=$(mktemp -u "${_tmp_dir}/tmpfile.XXXXXX")
  
  if [ "${DO_CONVERT}" == "true" ]; then
    image_convert_raw_to_jpg "${_originalfile}" "${_tmp_file}"
    _suffix="jpg" # Set the new suffix because we converted the original file to a jpeg.
     echo "INFO: Image converted to jpeg."
     jhead -autorot "${_tmp_file}"
     echo "INFO: Autorotation applied."
  else
    cp "${_originalfile}" "${_tmp_file}"
  fi

  [ "${DO_RESIZE}" == "true" ] && image_resize "${_tmp_file}" "${_tmp_file}" && echo "INFO: Image resized."
  [ "${DO_REMOVEMETADATA}" == "true" ] && image_remove_metadata "${_tmp_file}" && echo "INFO: Metadata removed."
  [ "${DO_OPTIMIZE}" == "true" ] && image_optimize "${_tmp_file}" "${_suffix}" && echo "INFO: Image optimized."
  shift
done

chmod a+r "${_tmp_file}"
_checksum=$(sha256sum "${_tmp_file}" | cut -d' ' -f1)

# Upload to the server.
scp -P "${_remote_port}" "${_tmp_file}" "${_remote_user}"@"${_remote_host}":"${_remote_destdir}"/"${_checksum}"."${_suffix}"

# Clean up
rm "${_tmp_file}"
rmdir "${_tmp_dir}"

_public_url="${_remote_public_http}${_checksum}.${_suffix}"

# Write to history file for later ...
echo "\"${_originalfile}\" => \"${_public_url}\"" >> "${_history_file}"

# Copy URL to clipboard.
echo -en "${_public_url}" | xsel -b

# Finished; let the user know the public URL for the shared file.
_msgtext="INFO: Local URL: \"${_originalfile}\"\nINFO: Remote URL: ${_public_url}\nPress Enter to quit..."
echo -en "${_msgtext}"

# Wait until user presses enter.
read _a
