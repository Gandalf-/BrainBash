#!/bin/bash

# Author : Austin Voecks
# Program: tm.sh
#   Turning Machine in Bash, uses Brainf$$k syntax
#   + : increment current position on tape
#   - : decrement current position on tape
#   > : move tape position once to the right
#   < : move tape position once to the left
#   [ : starts a loop, body entered when position value is non zero
#   ] : denotes the end of a loop
#   . : prints ascii value of current position
#   , : saves input from user to current position

set -o pipefail


# =========================================
# GLOBALS
# =========================================
declare -a chars              # array of characters, input
declare -a tape               # array of integers, memory
declare -a stack              # array of integers, call stack
declare -a profiler           # array of integers, instruction accounting

export tape_pos=0             # integer, our current position on the tape
export char_pos=0             # integer, our current position in the input
export brace_depth=0          # integer, number of nested braces
export stack_size=0           # integer, size of the stack

export green=\\0"33[01;32m"
export normal=\\0"033[00m"


# =========================================
# UTILITY
# =========================================
usage() {
  # shows usage information

  echo "
  usage: bash tm.sh [OPTION ...] (input file | program string)
    -c --compile     no execution, write parsed, optimized program to file
    -h --help        show help information
    -i --max_iter x  number of operations to run before early stopping
    -O --Optimize    apply advanced, heavy optimizations
    -o --optimize    apply basic optimizations
    -p --print       print out the program before execution
    -P --profile     show instruction execution information
    -q --quiet       suppress execution trace
    -r --raw         treat input as already parsed, use with compiled programs
    -S --step        only advance execution when user presses enter
    -s --stime x     sleep for x seconds between operations
  "
}

parse_options_and_input() {
  # process flags to set run time variables

  # options
  while [[ $2 ]]; do
    case $1 in
      -h|--help)      usage; exit         ;;
      -S|--step)      step=1              ;;
      -s|--stime)     shift; stime=$1     ;;
      -p|--print)     print=1             ;;
      -P|--profile)   profile=1           ;;
      -c|--compile)   compile=1           ;;
      -r|--raw)       raw_input=1         ;;
      -q|--quiet)     quiet=1             ;;
      -o|--optimize)  simple_optimize=1   ;;
      -O|--Optimize)  heavy_optimize=1    ;;
      -i|--max_iter)  shift; max_iters=$1 ;;
      *)              usage; exit         ;;
    esac
    shift
  done

  # input file or program string
  case $1 in
    ''|-h|--help) parse_options_and_input _ --help                 ;;
    *)            input="$1"; [[ -e "$1" ]] && input="$(cat "$1")" ;;
  esac
}

print_tape() {
  # prints the entire tape, marking the current position green

  local i; i=0
  echo -n "tape  : "

  while [[ ${tape[$i]} ]]; do
    if (( i == tape_pos )); then
      printf "%b%s%b" "$green" "${tape[$i]} " "$normal"
    else
      echo -n "${tape[$i]} "
    fi
    (( i++ ))
  done

  echo
}

print_chars() {
  # prints the entire input, marking the current position green

  local i; i=0
  echo -n "chars : "

  while [[ ${chars[$i]} ]] ; do
    if (( i == char_pos )); then
      printf "%b%s%b" "$green" "${chars[$i]} " "$normal"
    else
      echo -n "${chars[$i]} "
    fi
    (( i++ ))
  done

  echo
}

run_profiler() {
  # show what percentage of total execution each instruction took
  # useful for finding heavily repeated loops

  local instruction new_percent old_percent sum_percent b_depth size

  instruction=${chars[0]}
  old_percent="$( bc -l <<< "${profiler[0]} / $iters * 100" )"
  sum_percent=""
  b_depth=1
  b_change=0

  echo
  echo " % time : instruction(s)"
  echo "----------------------------------------------"
  for (( i=1; i < ${#profiler[@]}; i++ )); do
    new_percent="$( bc -l <<< "${profiler[$i]} / $iters * 100" )"

    # attempt to bundle "run together" strings of instructions together
    # "run together" means contiguous instructions with the same frequency
    if [[ "$new_percent" == "$old_percent" ]]; then
      if [[ -z "$sum_percent" ]]; then
        sum_percent="$(bc -l <<< "$old_percent + $new_percent")"
      else
        sum_percent="$(bc -l <<< "$sum_percent + $new_percent")"
      fi

      instruction="${instruction}${chars[$i]}"
      old_percent="$new_percent"

      [[ "${chars[$i]}" == "[" ]] && (( b_change++ ))
      [[ "${chars[$i]}" == "]" ]] && (( b_change-- ))

    else
      (( size=b_depth+${#instruction} ))

      if [[ -z "$sum_percent" ]]; then
        printf '% 7.2f :% *s\n' "$old_percent" "$size" "$instruction"
      else
        printf '% 7.2f :% *s\n' "$sum_percent" "$size" "$instruction"
      fi

      instruction="${chars[$i]}"
      old_percent="$new_percent"
      sum_percent=""

      (( b_depth+=b_change ))
      b_change=0

      [[ "${chars[$i]}" == "]" ]] && (( b_depth-- ))
      [[ "${chars[$i]}" == "[" ]] && (( b_depth++ ))
    fi
  done

  size=$(( b_depth + ${#instruction} ))

  if [[ -z "$sum_percent" ]]; then
    printf '% 7.2f :% *s\n' "$old_percent" "$size" "$instruction"
  else
    printf '% 7.2f :% *s\n' "$sum_percent" "$size" "$instruction"
  fi
}

shut_down() {

  (( execution_started )) && {
    # final output
    print_tape
    (( quiet )) || echo "operations: $iters"

    # profiler output
    (( profile )) && run_profiler
  }
  exit
}

# =========================================
# OPTIMIZATION
# =========================================
optimize_moves() {

  move_dec='\[-[<|>]\+[+|-]\+[>|<]\+\]'  # decrement, move left or right
  dec_move='\[[<|>]\+[+|-]\+[>|<]\+-\]'  # move, decrement left or right

  # recognize move operations, in the form [->>+<<] or [>>+<<-], where the
  # number of places moved is variable and saved to use during execution
  #   [->>>+<<<] -> 3a
  #   [-<<+>>]   -> 2A
  #
  # extended, includes variable number of increments. which would be a move
  # with and a multiply
  #   [->>+++<<]  -> 2a3
  #   [-<<<++>>>] -> 3A2
  while read -r move; do

    # escape brackets for sed
    move="$(sed -e 's/\[/\\\[/g' -e 's/\]/\\\]/g' <<< "$move" )"

    case $(grep -o '[>|<][+|-]\+[<|>]' <<< "${move}" | head -n 1) in
      # moving to the right some number of places
      # [->>+<<]
      '>+<')
        places=$(grep -o -- '>' <<< "${move}" | grep -c '>')
        tchars=$(sed -e "s/$move/${places}A/g" <<< "${tchars}")
        ;;
      # add many times to the right some number of places
      # [->>+++<<]
      '>+'*'<')
        places=$(grep -o -- '>' <<< "${move}" | grep -c '>')
        addition=$(grep -o -- '+' <<< "${move}" | grep -c '+')
        tchars=$(sed -e "s/$move/${addition}_${places}A/g" <<< "${tchars}")
        ;;

      # moving to the left some number of places
      '<+>')
        places=$(grep -o -- '<' <<< "${move}" | grep -c '<')
        tchars=$(sed -e "s/$move/${places}a/g" <<< "${tchars}")
        ;;
      # add many times to the left some number of places
      '<+'*'>')
        places=$(grep -o -- '<' <<< "${move}" | grep -c '<')
        addition=$(grep -o -- '+' <<< "${move}" | grep -c '+')
        tchars=$(sed -e "s/$move/${addition}_${places}a/g" <<< "${tchars}")
        ;;

      # subtracting to the right some number of places
      '>-<')
        places=$(grep -o -- '>' <<< "${move}" | grep -c '>')
        tchars=$(sed -e "s/$move/${places}S/g" <<< "${tchars}")
        ;;
      # subtracting many times to the right some number of places
      '>-'*'<')
        places=$(grep -o -- '>' <<< "${move}" | grep -c '>')
        subtraction=$(grep -o -- '-' <<< "${move}" | grep -c '-')
        (( subtraction-- ))  # decrement once for loop decrement
        tchars=$(sed -e "s/$move/${subtraction}_${places}S/g" <<< "${tchars}")
        ;;

      # subtracting to the left some number of places
      '<->')
        places=$(grep -o -- '<' <<< "${move}" | grep -c '<')
        tchars=$(sed -e "s/$move/${places}s/g" <<< "${tchars}")
        ;;

      *)
        echo "matched: $(
          grep -o -- '[>|<][+|-]\+[<|>]' <<< "${move}" | head -n 1)"
        ;;
    esac
  done < <(
    # shellcheck disable=SC1117
    grep -o -- "${move_dec}\|${dec_move}" <<< "${tchars}"
    )
}

optimize_copies() {

  copy_dec='\[-[>]*\(>+\)\+[<]\+\]'
  dec_copy='\[[>]*\(>+\)\+[<]\+\-]'

  # recognize copies
  #   we have to determine the number of copies and where each one is going
  while read -r move; do

    # escape brackets
    move="$(sed -e 's/\[/\\\[/g' -e 's/\]/\\\]/g' <<< "$move" )"

    # how many copies
    copies=$(grep -o -- '+' <<< "${move}" | grep -c '+')

    case $(grep -o -- '+[<|>]' <<< "${move}" | tail -n 1) in
      # copying to the right
      # the number of copies to make _ how far each copy is from other copies
      # _ an offset for the entire copy
      # [->+>+<<]     -> 2_1_0C
      # [->>>+>+<<<<] -> 2_1_2C
      '+<')
        places=1 #$(grep -o -- '>+' <<< "${move}" | grep -c '>+')
        shifts=$(( $(grep -o -- '<' <<< "${move}" | grep -c '<') - copies ))
        tchars=$(
          sed -e "s/$move/${copies}_${places}_${shifts}C/g" <<< "${tchars}")
        ;;

      # copying to the left
      # [-<+<+>>]
      '+>')
        places=$(grep -o -- '<' <<< "${move}" | grep -c '<')
        (( places/=copies ))
        tchars=$(sed -e "s/$move/${copies}_${places}c/g" <<< "${tchars}")
        ;;
      *)
        echo "fail"
        ;;
    esac
  done < <(
    # shellcheck disable=SC1117
    grep -o -- "$copy_dec\|$dec_copy" <<< "${tchars}"
    )
}

apply_heavy_optimizations() {

  # heavy optimizations are more complex
  optimize_moves

  # recognize zeroing
  tchars=$(sed -e 's/\[-\]/Z/g' <<< "$tchars")

  optimize_copies
}

apply_simple_optimizations() {

  # simple optimization recognizes repeated instructions and combines them.
  # for example >>>> becomes 4>

  # optimize repeated operations (2 or more occurrences)
  for operation in '---' '+++' '>>>' '<<<'; do

    # replace each match with it's simplified form
    while read -r match; do
      tchars=$(sed -e "s/$match/${#match}${operation::1}/g" <<< "${tchars}")
    done < <(grep -o -- "${operation}*" <<< "${tchars}" | sort -r)

  done
}


# =========================================
# MAIN
# =========================================
main() {

  local input='' quiet=0 step=0 stime=0 max_iters=1000000 iters=0
  local simple_optimize=0 heavy_optimize=0 execution_started=0
  local print=0 raw_input=0 compile=0 profile=0 counter=0
  local ops='' percent_fewer_instructions=0 percent_speed_up=0

  tape[0]=0

  parse_options_and_input "$@"

  # convert all lines of input to an array of characters
  if (( raw_input )); then
    tchars="$input"

  else
    tchars=$(grep -v '^[ ]*#.*' <<< "$input" |   # remove comments
             xargs -0                        |   # remove newlines
             grep -o .                       |   # separate each character
             grep '[]\+\>\<\[\.\,-]'         |   # remove non-syntax chars
             grep -v \\\\                    |   # remove pesky backslashes
             tr -d '\n')                         # back to one line
  fi
  plength=${#tchars}

  # optimizations
  (( heavy_optimize  )) && { apply_heavy_optimizations; simple_optimize=1; }
  (( simple_optimize )) &&   apply_simple_optimizations

  # optionally print the program and optimizing results
  (( print )) && {
    echo "program: $tchars"

    (( simple_optimize )) && {

      ops="$(sed 's/[0-9_]*//g' <<< "${tchars[@]}")"

      percent_fewer_instructions="$(
        bc -l <<< "(1 - (${#ops} / $plength)) * 100" )"

      percent_speed_up="$(
        bc -l <<< "(1 / (1 - $percent_fewer_instructions / 100) * 100 - 100)")"

      printf "optimized away %.2f%% of instructions; %.0f%% speed up" \
        "$percent_fewer_instructions" "$percent_speed_up"
    }
    echo
  }

  # compile option writes a new program file for use with the -r option
  (( compile )) && {
    echo "${tchars}" > "$input".raw
    exit
  }

  # convert tchar string to array for execution
  # shellcheck disable=SC2207
  chars=( $(grep -o -- '[_0-9]*.' <<< "$tchars") )

  # run the program
  execution_started=1

  while [[ ${chars[$char_pos]:-} && $iters -lt $max_iters ]]; do

    (( profiler[char_pos]++ ))

    if (( brace_depth > 0 )) ; then
      case ${chars[$char_pos]} in
        "]") (( brace_depth-- )) ;;
        "[") (( brace_depth++ )) ;;
      esac

    else
      (( quiet )) || print_chars

      # =========================================
      # OPERATIONS
      # =========================================
      # these are intentionally inlined for performance
      case ${chars[$char_pos]} in

        # composite add to the left
        [0-9]*'_'[0-9]*'a')
          # many times
          # [-<<+++>>] -> 3_2a
          # shellcheck disable=SC2206
          op_data=( ${chars[$char_pos]//_/ } )
          places=${op_data[1]::-1}
          amount=${op_data[0]}

          (( amount *= tape[tape_pos] ))
          (( tape[tape_pos-places] += amount ))
          (( tape[tape_pos] = 0 ))
          ;;
        [0-9]*'a')
          # once
          # [-<<+>>] 2a
          places=${chars[$char_pos]::-1}
          (( tape[tape_pos-places] += tape[tape_pos] ))
          (( tape[tape_pos] = 0 ))
          ;;

        # composite add to the right
        [0-9]*'_'[0-9]*'A')
          # many times
          # [->>+++<<] -> 3_2A
          # shellcheck disable=SC2206
          op_data=( ${chars[$char_pos]//_/ } )
          places=${op_data[1]::-1}
          amount=${op_data[0]}
          (( amount *= tape[tape_pos] ))

          if (( places > 1 )); then
            (( counter = tape_pos + places ))
            while [[ -z ${tape[$counter]:-} ]]; do
              ((
                tape[counter] = 0,
                counter--
              ))
            done
          fi
          ((
            tape[tape_pos + places] += amount,
            tape[tape_pos] = 0
          ))
          ;;
        [0-9]*'A')
          # once
          # [->>+<<] 2A
          places=${chars[$char_pos]::-1}

          (( places > 1 )) && {
            (( counter=tape_pos+places ))
            while [[ -z ${tape[$counter]:-} ]]; do
              ((
                tape[counter] = 0,
                counter--
              ))
            done
          }
          ((
            tape[tape_pos + places] += tape[tape_pos],
            tape[tape_pos] = 0
          ))
          ;;

        [0-9]*'s')
          # composite subtract to the left
          ((
            places = ${chars[$char_pos]::-1},
            tape[tape_pos - places] -= tape[tape_pos],
            tape[tape_pos] = 0
          ))
          ;;

        # composite subtract to the right
        [0-9]*'_'[0-9]*'S')
          # many times
          # [->>---<<] -> 3_2S
          # shellcheck disable=SC2206
          op_data=(${chars[$char_pos]//_/ })
          places=${op_data[1]::-1}
          amount=${op_data[0]}
          (( amount *= tape[tape_pos] ))

          if (( places > 1 )); then
            (( counter = tape_pos + places ))
            while [[ -z ${tape[$counter]:-} ]]; do
              ((
                tape[counter] = 0,
                counter--
              ))
            done
          fi
          ((
            tape[tape_pos+places] -= amount,
            tape[tape_pos]=0
          ))
          ;;
        [0-9]*'S')
          # once
          ((
            places = ${chars[char_pos]::-1},
            tape[tape_pos + places] -= tape[tape_pos],
            tape[tape_pos] = 0
          ))
          ;;

        Z)
          # composite set this position to zero
          # [-] -> Z
          (( tape[tape_pos] = 0 ))
          ;;

        [0-9]*'_'[0-9]*'_'[0-9]*C)
          # composite copy left
          # [->+>+<<]   -> 2_1_0C
          # [->++>++<<]
          # [->>+>+<<<] -> 2_1_1C
          # shellcheck disable=SC2206
          IFS=_ read -r copies shifts offset <<< "${chars[$char_pos]//C/ }"

          (( counter = shifts + offset ))
          while (( copies > 0 )); do
            ((
              tape[tape_pos + counter] += tape[tape_pos],
              copies--,
              counter += shifts
            ))
          done
          (( tape[tape_pos] = 0 ))
          ;;

        [0-9]*'+')
          # increment this position on the tape many times
          # 5+
          (( tape[tape_pos] += ${chars[char_pos]::-1} ))
          ;;
        "+")
          # increment this position on the tape
          # +
          (( tape[tape_pos]++ ))
          ;;

        [0-9]*'-')
          # - : decrement this position on the tape many times
          (( tape[tape_pos] -= ${chars[char_pos]::-1} ))
          ;;
        "-")
          # - : decrement this position on the tape
          (( tape[tape_pos]-- ))
          ;;

        [0-9]*'>')
          # > : shift tape position to the right many times,
          # check initialization
          ((
            tape_pos += ${chars[char_pos]::-1},
            counter = tape_pos
          ))
          while [[ -z ${tape[counter]} ]]; do
            ((
              tape[counter] = 0,
              counter--
            ))
          done
          ;;
        ">")
          # > : shift tape position to the right once, check initialization
          (( tape_pos++ ))
          [[ ${tape[$tape_pos]} ]] || (( tape[tape_pos] = 0 ))
          ;;

        [0-9]*'<')
          # < : shift tape position to the left many times, check underflow
          # (( tape_pos -= ${chars[$char_pos]::-1} ))
          (( tape_pos -= ${chars[char_pos]::-1} ))
          (( tape_pos < 0 )) && { echo "error: lshift < 0" ; exit; }
          ;;
        "<")
          # < : shift tape position to the left once, check if underflow
          (( tape_pos-- ))
          (( tape_pos < 0 )) && { echo "error: lshift < 0" ; exit; }
          ;;

        "]")
          # ] : if the jump stack has any elements, set the current character
          # position to the character before the lbrace. This way, we'll
          # encounter it as the next character. We then remove that position
          # from the jump stack
          if (( stack_size > 0 )); then
            (( char_pos = stack[stack_size] - 1 ))
            unset stack[${stack_size}]
            (( stack_size-- ))
          fi
          ;;

        "[")
          # [ : if the current tape value is greater than zero, save our
          # current position on the stack and run the contents of the loop.
          # Otherwise, seek to the next rbrace
          if (( tape[tape_pos] > 0 )); then
            ((
              stack_size++,
              stack[stack_size] = char_pos
            ))

          else
            (( brace_depth++ ))
          fi
          ;;

        ".")
          # . : add current position to output
          # shellcheck disable=SC2059,SC1117
          printf "\x$(printf %x "${tape[$tape_pos]}")"
          #output="${output} ${tape[$tape_pos]}"
          ;;

        ",")
          # , : saves input from user to current position
          echo -n "input?> "
          read -r value
          tape[$tape_pos]=${value}
          ;;

        *)
          echo "error: unrecognized instruction: ${chars[$char_pos]}"
          exit
          ;;
      esac

      # step, sleep, and/or print
      (( quiet )) || {
        print_tape

        if (( step )); then
          read -r _

        elif [[ $stime != 0 ]]; then
          sleep "$stime"
        fi

        echo
      }
    fi

    (( iters++ ))
    char_pos=$(( char_pos + 1 ))
  done

  (( iters == max_iters )) && echo "iteration maximum reached: $max_iters"

  shut_down
}

trap shut_down INT
main "$@"
