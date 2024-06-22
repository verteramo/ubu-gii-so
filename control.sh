#!/bin/bash

###
# @name:    Práctica de Control
# @brief:   Gestión de workspaces
# @author:  Marcelo Verteramo Pérsico <mvp1011@alu.ubu.es>
# @version: 1.0
# @date:    22/05/2024
# @exec:    ./control.sh
##

#######################################
# Secuencia de escape ANSI
#######################################

# Secuencias especiales
readonly default="\033[0m"
readonly underline="\033[4m"
readonly blink="\033[5m"

# Colores
readonly red="\033[0;31m"
readonly green="\033[0;32m"
readonly yellow="\033[0;33m"
readonly blue="\033[0;34m"
readonly cyan="\033[0;36m"
readonly grey="\033[0;90m"
readonly lightred="\033[1;31m"
readonly lightgreen="\033[1;32m"
readonly lightblue="\033[1;34m"
readonly lightgrey="\033[0;37m"

function erase_line() (echo -ne "\033[K")
function cursor_up() (echo -ne "\033[${1}A")
function cursor_save() (echo -ne "\033[s")
function cursor_hide() (echo -ne "\033[?25l")
function cursor_show() (echo -ne "\033[?25h")
function cursor_restore() (echo -ne "\033[u")
function cursor_forward() (echo -ne "\033[${1}C")

#######################################
# Funciones de impresión
#######################################

function print_break() (echo -ne "${red}${1}${default}")
function print_blink() (echo -ne "${blink}${1}${default}")
function print_shiny() (echo -ne "${yellow}${blink}${1}${default}")
function print_title() (echo -ne "${blue}${underline}${1}${default}")
function print_dimmed() (echo -ne "${grey}${1}${default}")
function print_prompt() (echo -ne "${yellow}${1}${default}")
function print_heading() (echo -ne "${cyan}${1}${default}")
function print_default() (echo -ne "${default}${1}${default}")
function print_positive() (echo -ne "${lightgreen}${1}${default}")
function print_negative() (echo -ne "${lightred}${1}${default}")
function print_highlight() (echo -ne "${lightblue}${1}${default}")

#######################################
# Teclas
#######################################

readonly up="A"
readonly down="B"
readonly intro=""

#######################################
# Expresiones regulares
#######################################

# Patrón para opciones deshabilitadas
readonly pattern_disabled_option='(^\^|^$)'

# Patrón para opciones de menú
readonly pattern_menu_option='^-'

#######################################
# Configuración
#######################################

# Tamaño de la sangría
indent=2

# Carácter de selección
selection_char=">"

# Tamaño máximo del nombre
name_length=16

# Directorio del script
basedir="$(dirname "${0}")"

# Directorio base
basepath="${basedir}/storage_mvp"

# Fichero de log
logfile="${basepath}/access.log"

# Prefijo de los grupos
group_prefix="sso"

#######################################
# Cadenas de texto
#######################################

str_access="Acceso"
str_action="Acción"
str_add_files="Añadir ficheros"
str_create="Crear"
str_creation="Creación"
str_date="Fecha"
str_del="Eliminar"
str_edit="Editar"
str_empty="Vacío"
str_no_results="No hay resultados"
str_error_invalid_option="Opción inválida"
str_exit="Salir"
str_file="Fichero"
str_files="Ficheros"
str_logs="Registros de actividad"
str_menu="Menú"
str_name="Nombre"
str_pause="Intro para continuar..."
str_positive_answers="Ss"
str_prompt_name="Nombre (Intro para cancelar) > "
str_restore="Restaurar"
str_restored="Sistema restaurado"
str_return="Volver"
str_search="Buscar"
str_size="Tamaño"
str_admin_title="Administración de áreas de trabajo"
str_user_title="Búsqueda de ficheros"
str_user="Usuario"
str_sys_users="Usuarios del sistema"
str_ws_users="Usuarios del área de trabajo"
str_view="Ver"
str_workspace="Área de trabajo"
str_workspaces="Áreas de trabajo"

str_action_copy="Copiado"
str_action_create="Creado"
str_action_del="Eliminado"
str_action_update="Actualizado"
str_action_user_added="Usuario añadido: '%s'"
str_action_user_del="Usuario eliminado: '%s'"

str_info_added="Añadido: '%s'"
str_info_del="Eliminado: '%s'"
str_info_exists="El área de trabajo '%s' ya existe"
str_info_not_found="Fichero no encontrado: '%s'"
str_info_overwrite="Fichero sobrescrito: '%s'"
str_info_not_overwrite="No se ha sobrescrito: '%s'"
str_warn_add_user="¿Añadir usuario '%s'?"
str_warn_del_user="¿Eliminar usuario '%s'?"
str_warn_del="¿Eliminar '%s'? Acción irreversible"
str_warn_overwrite="¿Sobrescribir '%s'? Acción irreversible"
str_warn_restore="¿Restaurar sistema? Acción irreversible"

str_mail_subject="Añadido a '%s'"
str_mail_body="Ha sido añadido al área de trabajo '%s'"

# Formato del mensaje de ayuda
str_help=$(
  cat <<EOM
${blue}Práctica de Control
${green}Marcelo Verteramo Pérsico <mvp1011@alu.ubu.es>
${yellow}${blink}
_________                __                .__   
\_   ___ \  ____   _____/  |________  ____ |  |  
/    \  \/ /  _ \ /    \   __\_  __ \/  _ \|  |  
\     \___(  <_> )   |  \  |  |  | \(  <_> )  |__
 \______  /\____/|___|  /__|  |__|   \____/|____/
        \/            \/         Áreas de trabajo
${default}
Uso: $0 [opciones]
Opciones:
  -h, --help  Muestra este mensaje de ayuda
EOM
)

#######################################
# Formatos
#######################################

# Formato de fecha y hora
date_format="%Y/%m/%d %H:%M:%S"

# Formato de cabecera de filesystem
readonly fs_header="$(printf "${underline}| %-${name_length}s | %-17s | %-16s | %-6s |\n" "${str_name}" "${str_creation}" "${str_access}" "${str_size}")"

# Formato de fila de filesystem
readonly fs_row="| %-${name_length}f | %Cd/%Cm/%CY %CH:%CM | %Ad/%Am/%AY %AH:%AM | %-6s |"

# Formato de cabecera de log
readonly log_header="$(printf "${underline}| %-19s | %-7s | %-${name_length}s | %-${name_length}s | %-14s \n" "${str_date}" "${str_user}" "${str_workspace}" "${str_file}" "${str_action}")"

# Formato de fila de log
readonly log_row="| %-19s | %-7s | %-$(($name_length - 1))s | %-${name_length}s | %-14s \n"

#######################################
# Funciones de interacción
#######################################

###
# Menú de selección
# @param $1: Referencia a la variable de salida
# @param ${@:2}: Opciones del menú
#
# @link: https://www.gnu.org/software/bash/manual/html_node/Special-Parameters.html
##
function selection {
  # Referencia a la variable seleccionada
  local -n _selected_option_=$1

  # Desplazamiento del primer argumento
  shift

  # Avanzar la primera opción mientras esté deshabilitada
  local first_option=1
  while [[ "${!first_option}" =~ $pattern_disabled_option ]]; do
    ((first_option++))
  done

  # Retroceder la última opción mientras esté deshabilitada
  local last_option=$#
  while [[ "${!last_option}" =~ $pattern_disabled_option ]]; do
    ((last_option--))
  done

  # Seleccionar la primera opción si no hay ninguna seleccionada
  _selected_option_=${_selected_option_:-$first_option}
  # Si la opción seleccionada está fuera de rango, se establece la primera opción
  ((_selected_option_ < first_option || _selected_option_ > last_option)) &&
    _selected_option_=$first_option

  while [[ "${@:_selected_option_:1}" =~ $pattern_disabled_option ]]; do
    ((_selected_option_++))
  done

  # Ocultar el cursor
  cursor_hide

  # Bucle de selección
  while true; do
    for ((option = 1; option <= $#; option++)); do
      erase_line
      # Si la opción está seleccionada
      if ((option == _selected_option_)); then
        # Se imprime el carácter de selección
        print_default "${selection_char}"
        ((indent - ${#selection_char} > 0)) &&
          cursor_forward $(($indent - ${#selection_char}))
        # Se imprime la opción seleccionada con su formato correspondiente
        case ${!option} in
        -!*) print_break "${!option:2}" ;;
        -*) print_highlight "${!option:1}" ;;
        *) print_positive "${!option}" ;;
        esac
      else
        ((indent > 0)) && cursor_forward $indent
        # Se imprime la opción no seleccionada con su formato correspondiente
        case ${!option} in
        ^#*) print_heading "${!option:2}" ;;
        ^*) print_dimmed "${!option:1}" ;;
        -!*) print_default "${!option:2}" ;;
        -*) print_default "${option_enabled}${!option:1}" ;;
        *) print_default "${option_enabled}${!option}" ;;
        esac
      fi
      print_default "\n"
    done
    # Lectura y evaluación de la tecla pulsada
    read -sn1 key
    case "${key}" in
    # Flecha arriba: decrementar la opción seleccionada hasta la anterior habilitada
    $up)
      ((_selected_option_ == first_option)) && _selected_option_=$last_option || ((_selected_option_--))
      while [[ "${@:_selected_option_:1}" =~ $pattern_disabled_option ]]; do
        ((_selected_option_--))
      done
      ;;

    # Flecha abajo: incrementar la opción seleccionada hasta la siguiente habilitada
    $down)
      ((_selected_option_ == last_option)) && _selected_option_=$first_option || ((_selected_option_++))
      while [[ "${@:_selected_option_:1}" =~ $pattern_disabled_option ]]; do
        ((_selected_option_++))
      done
      ;;

    # Intro: finalizar la selección
    $intro) break ;;
    esac

    # Se mueve el cursor al inicio de la lista
    cursor_up $#
  done

  # Mostrar el cursor
  cursor_show
}

###
# Pregunta al usuario
# @param $1: Mensaje de la pregunta
# @param $2: Respuestas positivas
##
function question {
  cursor_hide

  print_prompt "${1} (${2}) > "
  read -n1 key

  cursor_show

  for ((i = 0; i < ${#2}; i++)); do
    if [ "${key}" == "${2:$i:1}" ]; then
      return 0
    fi
  done

  return 1
}

###
# Pausa la ejecución del script hasta que se pulse Intro
##
function pause {
  cursor_hide
  print_blink "${str_pause}"
  read
  cursor_show
}

#######################################
# Funciones de negocio
#######################################

###
# Workspaces
# @param $1: Formato de salida
##
function get_workspaces {
  find "${basepath}" -mindepth 1 -maxdepth 1 -type d -printf "${1}\n" | sort
}

###
# Ficheros de un workspace
# @param $1: Nombre del workspace
# @param $2: Formato de salida
##
function get_files {
  find "${basepath}/${1}" -mindepth 1 -maxdepth 1 -type f -printf "${2}\n" | sort
}

function get_readable_files {
  find "${basepath}" -mindepth 2 -maxdepth 2 -type f -readable -name "*${1}*" -printf "${2}\n" | sort
}

###
# Grupos con prefijo de workspace
##
function get_groups {
  awk -F: -v prefix="^${group_prefix}_" '{
    if ($1 ~ prefix) {
      print $1
    }
  }' /etc/group
}

###
# Usuarios del sistema o de un grupo
# @param $1: Nombre del grupo
##
function users {
  if [[ ! "${1}" ]]; then
    awk -F: '{
      if ($3 >= 1000 && $7 ~ "sh$") print $1
    }' /etc/passwd
  else
    awk -F: -v group="${group_prefix}_${1/ /_}" '{
      if ($1 == group) print $4
    }' /etc/group | tr ',' '\n' | sed '/^\s*$/d'
  fi
}

###
# Usuarios no asignados a un workspace
# @param $1: Nombre del workspace
##
function users_diff {
  comm -23 <(users | sort) <(users "${1}" | sort)
}

###
# Registra una acción en el log
# @param $1: Nombre del workspace
# @param $2: Nombre del fichero
# @param $3: Acción realizada
##
function log {
  echo "$(date +"${date_format}");${USER};${1};${2};${3}" >>"${logfile}"
}

#######################################
# Funciones de ficheros
#######################################

###
# Elimina un fichero
# @param $1: Ruta del fichero
##
function file_del {
  # Se requiere confirmación
  if question "$(printf "\n${str_warn_del}" "$(basename "${1}")")" "${str_positive_answers}"; then
    rm "${1}"
    return 0
  fi

  return 1
}

###
# Muestra el contenido de un fichero
# @param $1: Ruta del fichero
##
function file_show {
  clear
  if [[ "${1}" ]]; then
    print_title "${str_workspace}: ${1} - ${str_file}: $(basename "${2}")\n\n"
  else
    print_title "${str_file}: $(basename "${2}")\n\n"
  fi
  print_default "$(less -N "${2}")\n\n"
  pause
}

###
# Menú de fichero
# @param $1: Ruta del fichero
##
function file_menu {
  while true; do
    clear
    print_title "${str_workspace}: ${1} - ${str_file}: $(basename "${2}")\n\n"
    selection selected \
      "^#${str_menu}" "-${str_view}" "-${str_edit}" "-${str_del}" "-!${str_return}"

    case $selected in
    2) file_show "${1}" "${2}" ;;
    3) ${EDITOR:-nano} "${2}" ;;
    4) file_del "${2}" && break ;;
    5) break ;;
    esac
  done
}

#######################################
# Funciones de usuarios
#######################################

###
# Añade un usuario a un workspace
# @param $1: Nombre del workspace
# @param $2: Nombre del usuario
##
function ws_add_user {
  if question "$(printf "${str_warn_add_user}" "${2}")" "${str_positive_answers}"; then
    # Se añade el usuario al grupo
    usermod -aG "${group_prefix}_${1/ /_}" "${2}"
    # Se registra la acción en el log
    log "${1}" "" "$(printf "${str_action_user_added}" "${2}")"
    # Se notifica al usuario
    mail -s "$(printf "${str_mail subject}" "${1}")" "${2}" <<<"$(printf "${str_mail_body}" "${1}")"
  fi
}

###
# Elimina un usuario de un workspace
# @param $1: Nombre del workspace
# @param $2: Nombre del usuario
##
function ws_del_user {
  if question "$(printf "${str_warn_del_user}" "${2}")" "${str_positive_answers}"; then
    # Se elimina el usuario del grupo
    gpasswd --del "${2}" "${group_prefix}_${1/ /_}"
    # Se registra la acción en el log
    log "${1}" "" "$(printf "${str_action_user_del}" "${2}")"
  fi
}

####################################
# Funciones de workspace
####################################

###
# Muestra una tabla de ficheros de un workspace
# @param $1: Nombre del workspace
##
function ws_table {
  local rows

  readarray -t rows < <(get_files "${1}" "${fs_row}")

  if ((!${#rows[@]})); then
    print_dimmed "${indentation}${str_empty}\n"
  else
    print_dimmed "${indentation}${fs_header}\n"
    for row in "${rows[@]}"; do
      print_default "${indentation}${row}\n"
    done
  fi
}

###
# Añade ficheros a un workspace
# @param $1: Nombre del workspace
##
function ws_add_files {
  local filename

  while true; do
    clear
    print_title "${str_workspace}: ${1} - ${str_add_files}\n\n"
    ws_table "${1}"
    print_prompt "\n${str_prompt_name}"
    read filename

    if [[ "${filename}" ]]; then
      if [ -f "${filename}" ]; then
        local target="${basepath}/${1}/$(basename "${filename}")"

        if [ -f "${target}" ]; then
          if question "$(printf "${str_warn_overwrite}" "$(basename "${filename}")")" "${str_positive_answers}"; then
            cp "${filename}" "${target}"
            chgrp "${group_prefix}_${1/ /_}" "${target}"
            chmod o-rwx "${target}"
            log "${1}" "$(basename "${target}")" "${str_action_copy}"
            print_positive "\n$(printf "${str_info_overwrite}" "$(basename "${target}")")\n"
            pause
          else
            print_default "\n$(printf "${str_info_not_overwrite}" "$(basename "${target}")")\n"
            pause
          fi
        elif [ ! -f "${target}" ]; then
          cp "${filename}" "${target}"
          chgrp "${group_prefix}_${1/ /_}" "${target}"
          chmod o-rwx "${target}"
          log "${1}" "$(basename "${target}")" "${str_action_copy}"
        fi
      else
        print_negative "$(printf "${str_info_not_found}" "${filename}")\n"
        pause
      fi
    else
      break
    fi
  done
}

###
# Creación de un workspace
##
function ws_add {
  local name
  local group
  local directory

  # Solicitud del nombre del workspace
  print_prompt "\n${str_prompt_name}"
  read name

  if [[ "${name}" ]]; then
    # Sanitización del nombre
    name="${name/\//_}"
    name="${name:0:name_length}"
    directory="${basepath}/${name}"

    if [ -d "${directory}" ]; then
      print_negative "$(printf "${str_info_exists}" "${name}")"
      read
    else
      group="${group_prefix}_${name/ /_}"
      mkdir -p "${directory}"
      groupadd "${group}" 2>/dev/null
      chgrp "${group}" "${directory}"
      chmod u-rwx "${directory}"
      log "${name}" "" "${str_action_create}"
    fi
  else
    break
  fi
}

###
# Eliminación de un workspace
# @param $1: Nombre del workspace
##
function ws_del {
  # Se requiere confirmación
  if question "$(printf "${str_warn_del}" "${1}")" "${str_positive_answers}"; then
    rm -rf "${basepath}/${1}"
    groupdel "${group_prefix}_${1/ /_}" 2>/dev/null
    log "${1}" "" "${str_action_del}"
    return 0
  fi

  return 1
}

###
# Menú de workspace
# @param $1: Nombre del workspace
##
function ws_menu {
  local name="${1}"
  local shift1
  local shift2
  local shift3
  local options
  local selected

  # Bucle de menú
  while true; do
    clear
    # Generación de las opciones de menú
    options=("^#${str_menu}" "-${str_add_files}" "-${str_del}" "-!${str_return}" "")

    # Generación de las opciones de usuarios no asignados
    readarray -t users_diff < <(users_diff "${name}")

    if ((!${#users_diff[@]})); then
      options+=("^#${str_sys_users}" "^${str_empty}" "")
    else
      options+=("^#${str_sys_users}" "${users_diff[@]}" "")
    fi

    shift1=${#options[@]}

    # Generación de las opciones de usuarios
    readarray -t users < <(users "${name}")

    if ((!${#users[@]})); then
      options+=("^#${str_ws_users}" "^${str_empty}" "")
    else
      options+=("^#${str_ws_users}" "${users[@]}" "")
    fi

    shift2=${#options[@]}

    # Generación de las opciones de ficheros
    readarray -t rows < <(get_files "${name}" "${fs_row}")
    readarray -t paths < <(get_files "${name}" "%p")

    if ((!${#rows[@]})); then
      options+=("^#${str_files}" "^${str_empty}" "")
    else
      options+=("^#${str_files}" "^${fs_header}" "${rows[@]}" "")
    fi

    shift3=${#options[@]}

    # Impresión del menú
    print_title "${str_workspace}: ${name}\n\n"
    selection selected "${options[@]}"

    # Evaluación de la opción seleccionada
    case $selected in
    2) ws_add_files "${name}" ;;
    3) ws_del "${name}" && break ;;
    4) break ;;
    *)
      if ((selected < shift1)); then
        ws_add_user "${name}" "${users_diff[selected - shift1 + ${#users_diff[@]}]}"
      elif ((selected < shift2)); then
        ws_del_user "${name}" "${users[selected - shift2 + ${#users[@]}]}"
      elif ((selected < shift3)); then
        file_menu "${name}" "${paths[selected - shift3 + ${#paths[@]}]}"
      fi
      ;;
    esac
  done
}

#######################################
# Funciones de sistema
#######################################

###
# Comprobación de la posibilidad de restaurar el sistema
##
function can_restore {
  if (($(get_workspaces | wc -l) || $(get_groups | wc -l))); then
    return 0
  fi

  return 1
}

###
# Restauración del sistema
##
function system_restore {
  if question "\n${str_warn_restore}" "${str_positive_answers}"; then
    # Eliminación de los workspaces
    rm -rf "${basepath}"/*

    # Eliminación de los grupos
    while read -r group; do
      groupdel "${group}"
    done < <(get_groups)

    print_positive "\n${str_restored}\n"
    pause
  fi
}

function show_logs {
  clear
  print_title "${str_logs}\n\n"
  if [ -s "${logfile}" ]; then
    print_dimmed "${indentation}${log_header}\n"
    awk -F";" -v format="${indentation}${log_row}" '{
      printf format, $1, $2, $3, $4, $5
    }' "${logfile}"
  else
    print_dimmed "${indentation}${str_empty}\n"
  fi
  print_default "\n"
  pause
}

###
# Menú de administración
##
function admin_menu {
  local rows
  local names
  local options
  local selected

  while true; do
    clear

    # Generación de las opciones de menú
    if can_restore; then
      options=("^#${str_menu}" "-${str_create}" "-${str_logs}" "-${str_restore}" "-!${str_exit}" "")
    else
      options=("^#${str_menu}" "-${str_create}" "-${str_logs}" "^${str_restore}" "-!${str_exit}" "")
    fi

    # Adición de los workspaces al menú
    readarray -t rows < <(get_workspaces "${fs_row}")
    readarray -t names < <(get_workspaces "%f")

    if ((!${#rows})); then
      options+=("^#${str_workspaces}" "^${str_empty}")
    else
      options+=("^#${str_workspaces}" "^${fs_header}" "${rows[@]}")
    fi

    # Impresión del menú
    print_title "${str_admin_title}\n\n"
    selection selected "${options[@]}"

    # Evaluación de la opción seleccionada
    case $selected in
    2) ws_add ;;
    3) show_logs ;;
    4) system_restore ;;
    5) break ;;
    *) ws_menu "${names[selected - 9]}" ;;
    esac
  done
}

###
# Menú de búsqueda de ficheros
##
function search_menu {
  local rows
  local paths
  local selected

  while true; do
    clear
    # Impresión del título
    print_title "${str_user_title} (${USER})\n\n"
    print_prompt "Buscar (Intro para cancelar) > "
    read input

    if [[ "${input}" ]]; then
      readarray -t rows < <(get_readable_files "${input}" "${fs_row}")
      readarray -t paths < <(get_readable_files "${input}" "%p")
      if ((!${#rows[@]})); then
        print_dimmed "\n${indentation}${str_no_results}\n\n"
      else
        selection selected "" "^${fs_header}" "${rows[@]}" "" "-!${str_exit}"

        if ((selected <= ${#rows[@]} + 3)); then
          file_show "" "${paths[selected - 3]}"
        else
          break
        fi
      fi
    else
      break
    fi
  done
}

#######################################
# Inicialización
#######################################

# Creación del directorio base
if [ ! -d "${basepath}" ]; then
  mkdir -p "${basepath}"
fi

# Establecimiento de la sangría
for ((i = 1; i <= indent; i++)); do
  indentation+=" "
done

# Comprobación de los argumentos
while [ $# -gt 0 ]; do
  case "$1" in
  -h | --help)
    print_default "${str_help}\n"
    exit 0
    ;;
  *)
    print_negative "$(printf "${str_error_invalid_option}" "$1")\n"
    exit 1
    ;;
  esac
done

#######################################
# Ejecución del script
#######################################

(($(id -u))) && search_menu || admin_menu
