// main


import "C"
import "str"
import "assert"
import "sys/path"
import "sys/fs"
import "data/list"
import "data/map"
import "cfg"
import "settings"
import "src"
import "error"
import "type"
import "value/misc"
//import "value/nat"
import "stmt"
import "prn/assembly"
import "value/2str"
import "type/print"
import "parser"
import "prn"
import "prn/init"
import "init"



let ARCH_DEFAULT_VALUE = Arch_x64


let VERSION_MAJOR = 0
let VERSION_MINOR = 5



let main = func (argc : Int, argv : []Str) -> Int {
  printf("m2 v%d.%d\n", VERSION_MAJOR, VERSION_MINOR)
  /*if argv[1] == Nil {
    usage()
    exit(1)
  }*/

  init()


  var arch : Arch
  arch = ARCH_DEFAULT_VALUE  // set default architecture

  let n = argc
  var argp : Int
  argp = 1
  while argp < n {
    let arg = argv[argp]
    printf("parse arg: %s\n", arg)
    if strncmp(arg, "arch=", 5) == 0 {
      if strcmp(&arg[5] to Str, "cortex-m3") == 0 {
        printf("arch=cortex-m3\n")
        arch = Arch_ARM_CM3
      } else if strcmp(&arg[5] to Str, "x64") == 0 {
        printf("arch=x64\n")
        arch = Arch_x64
      }
    }

    if strncmp(arg, "lib=", 4) == 0 {
      printf("add lib\n")
      liblist_add(&arg[4] to Str)
    }

    argp = argp + 1
  }



  // let's start!
  parse(source_open("main"))

  printf("lines: %d\n", lines)

  checkMain()

  //showValues()
  //showTypes()

  if errcnt > 0 {
    printf("error : %d\n", errcnt)
    return errcnt to Int
  }

  printer_init(arch, "main.ll")
  print_assembly(&asm0)

  return (errcnt != 0) to Int
}


let usage = func () -> Unit {
  printf("usage:\n")
  printf("  m2 <target>\n\n")
}



let showTypes = func () -> Unit {
  let shwt = func MapForeachHandler {
    let len = strlen(k)
    printf("* %s", k)

    let maxnamelen = 40

    var i : Nat32
    i = 0
    while i < (maxnamelen - len) {
      printf(" ")
      i = i + 1
    }

    let t = v to *Type
    prttype(t)
    printf("\n")
  }
  map_foreach(&mctx.type_index, shwt, Nil)
}


let showValues = func () -> Unit {
  let shwv = func MapForeachHandler {
    let len = strlen(k)
    printf("VAL: %s", k)

    let maxnamelen = 40

    var i : Nat32
    i = 0
    while i < (maxnamelen - len) {
      printf(" ")
      i = i + 1
    }

    prttype((v to *Value).type)
    printf("\n")
  }
  map_foreach(&mctx.value_index, shwv, Nil)
}



/* m2 Minor Compiler */
