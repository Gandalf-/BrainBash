## BrainBash

A **fast** Brainf\*\*k interpreter in pure Bash

```
I leaf@home ~/g/c/s/BrainBash> bash tm.sh -q -p -P -O programs/optimize.bf

program: 25+50_1A>15_5A
optimzed away 96.33% of instructions; 2625% speed up
tape  : 0 0 0 0 0 0 18750

 % time : instuction(s)
----------------------------------------------
 100.00 : 25+50_1A>15_5A
```


### Bash?

Yes, **tm.sh** is a 600+ line Bash script. Why Bash? The language actually
lends itself fairly well to this kind of problem space - working with text.
Even if you're not interested in Brainf\*\*k, **tm.sh** showcases a wide
variety of advanced Bash features such as:
- process substitution
- parameter substitution
- arrays
- built ins
- globs

### Features

**tm.sh** provides a number of features:
- interactive interpreter
- extensive optimizations
- colorized execution tracing
- compilation, in the way of saving optimizations for later
- built in execution profiler

### Options

**tm.sh** provides a number of options:

```
  leaf@home ~/g/c/s/BrainBash> bash tm.sh --help

  usage: bash tm.sh [OPTION]... input_file
    -c --compile     no execution, write parsed, optimized program to file
    -h --help        show help information
    -i --max_iter x  number of operations to run before early stopping
    -p --print       print out the program before execution
    -P --profile     show instruction execution information
    -o --optimize    apply basic optimizations
    -O --Optimize    apply advanced, heavy optimizations
    -q --quiet       suppress execution trace
    -r --raw         treat input as already parsed, use with compiled programs
    -s --stime x     sleep for x seconds between operations
    -S --step        only advance execution when user presses enter
```

### Fast start
```
  git clone https://github.com/Gandalf-/BrainBash.git
  cd BrainBash
  bash tm.sh -q programs/hello_world.bf
```

### Example usage:

These snippets show an example program including user input and the results of
different levels of optimizations. You'll notice that the first run was cut
short. **tm.sh** by default limits execution to 1,000,000 instructions.

```
  leaf@home ~/g/c/s/BrainBash> time bash tm.sh -p -q programs/fibonacci.bf
  program: +>+>>>>,[<<<<<[->>+>+<<<]>>>[<<<+>>>-]<<[->>+>+<<<]>>>[-<<<+>>>]<[-<+>]>>[->+<]>-]
  input?> 20
  tape  : 1 1 2 3 5 8 13 21 34 55 89 144 233 377 610 987 1597 2584 4181 6765 2683 6765 10946 8263 1

  real    0m53.749s
  user    0m43.664s
  sys     0m5.764s

  leaf@home ~/g/c/s/BrainBash> time bash tm.sh -p -q -o programs/fibonacci.bf
  program: +>+4>,[5<[-2>+>+3<]3>[3<+3>-]2<[-2>+>+3<]3>[-3<+3>]<[-<+>]2>[->+<]>-]
  optimized away 32.9300% of instructions; 49% speed up
  input?> 20
  tape  : 1 1 2 3 5 8 13 21 34 55 89 144 233 377 610 987 1597 2584 4181 6765 10946 17711 0 0 0 0

  real    0m48.181s
  user    0m39.615s
  sys     0m6.472s

  leaf@home ~/g/c/s/BrainBash> time bash tm.sh -p -q -O programs/fibonacci.bf
  program: +>+4>,[5<2_1_1C3>3a2<2_1_1C3>3a<1a2>1A>-]
  optimized away 74.4000% of instructions; 290% speed up
  input?> 20
  tape  : 1 1 2 3 5 8 13 21 34 55 89 144 233 377 610 987 1597 2584 4181 6765 10946 17711 0 0 0 0

  real    0m0.985s
  user    0m0.093s
  sys     0m0.085s
```

### Example profiler usage:

These snippets show some example output from using the program profiler. The
program's execution is broken into contiguous sequences of operations that are
all run the same number of times. Identation corresponds to the level of loop
depth.

```
leaf@home ~/g/c/s/BrainBash> bash tm.sh --quiet --profile --print programs/fibonacci.bf
program: +>+>>>>,[<<<<<[->>+>+<<<]>>>[<<<+>>>-]<<[->>+>+<<<]>>>[-<<<+>>>]<[-<+>]>>[->+<]>-]

input?> 10
tape  : 1 1 2 3 5 8 13 21 34 55 89 144 0 0 0 0

 % time : instuction(s)
----------------------------------------------
   0.08 : +>+>>>>,
   0.64 :  [<<<<<
  16.30 :   [->>+>+<<<]
   0.32 :  >>>
  14.82 :   [<<<+>>>-]
   0.21 :  <<
  25.62 :   [->>+>+<<<]
   0.32 :  >>>
  23.29 :   [-<<<+>>>]
   0.11 :  <
  13.97 :   [-<+>]
   0.21 :  >>
   3.81 :   [->+<]
   0.32 :  >-]

leaf@home ~/g/c/s/BrainBash> bash tm.sh --quiet --profile --print --Optimize programs/fibonacci.bf
program: +>+4>,[5<2_1_1C3>3a2<2_1_1C3>3a<1a2>1A>-]
optimized away 74.4000% of instructions; 290% speed up

input?> 20
tape  : 1 1 2 3 5 8 13 21 34 55 89 144 233 377 610 987 1597 2584 4181 6765 10946 17711 0 0 0 0

 % time : instuction(s)
----------------------------------------------
   1.47 : +>+4>,
  98.53 :  [5<2_1_1C3>3a2<2_1_1C3>3a<1a2>1A>-]

```
