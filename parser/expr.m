// m2/parser/expr



type ValueParser = () -> *Value



let expr = func ValueParser {return hier1()}
//let expr = hier1  // не работает тк он вызывает @expr вместо @hier1

// used in parser/type
// parse constant expression
let cexpr = func ValueParser {
  let v = expr()
  if v == Nil {goto fail}


  // in [x]X we need only imm const
  if not valueIsConst(v) {
    error("expected constant value", v.ti)
    goto fail
  }

  return v
fail:
  return Nil
}


let hier1 = func ValueParser {
  var v : *Value
  v = hier2()
  if v == Nil {return Nil}
  let ti = &ctok().ti
  if match("or") {
    skip_nl()
    let l = v
    let r = hier1()
    v = bin(ValueOr, l, r, ti)
  }
  return v
}


let hier2 = func ValueParser {
  var v : *Value
  v = hier3()
  if v == Nil {return Nil}
  let ti = &ctok().ti
  if match("xor") {
    skip_nl()
    let l = v
    let r = hier2()
    v = bin(ValueXor, l, r, ti)
  }
  return v
}


let hier3 = func ValueParser {
  var v : *Value
  v = hier4()
  if v == Nil {return Nil}
  let ti = &ctok().ti
  if match("and") {
    skip_nl()
    let l = v
    let r = hier3()
    v = bin(ValueAnd, l, r, ti)
  }
  return v
}


let hier4 = func ValueParser {
  var v : *Value
  v = hier5()
  if v == Nil {return Nil}
  while True {
    let ti = &ctok().ti
    if match("==") {
      skip_nl()
      let l = v
      let r = hier4()
      v = bin(ValueEq, l, r, ti)
    } else if match("!=") {
      skip_nl()
      let l = v
      let r = hier4()
      v = bin(ValueNe, l, r, ti)
    } else {
      break
    }
  }
  return v
}


let hier5 = func ValueParser {
  var v : *Value
  v = hier6()
  if v == Nil {return Nil}
  while True {
    let ti = &ctok().ti
    if match("<") {
      skip_nl()
      let l = v
      let r = hier6()
      v = bin(ValueLt, l, r, ti)
    } else if match(">") {
      skip_nl()
      let l = v
      let r = hier6()
      v = bin(ValueGt, l, r, ti)
    } else if match("<=") {
      skip_nl()
      let l = v
      let r = hier6()
      v = bin(ValueLe, l, r, ti)
    } else if match(">=") {
      skip_nl()
      let l = v
      let r = hier6()
      v = bin(ValueGe, l, r, ti)
    } else {
      break
    }
  }
  return v
}


let hier6 = func ValueParser {
  var v : *Value
  v = hier7()
  if v == Nil {return Nil}
  while True {
    let ti = &ctok().ti
    if match("<<") {
      skip_nl()
      let l = v
      let r = hier7()
      v = shift(ValueShl, l, r, ti)
    } else if match(">>") {
      skip_nl()
      let l = v
      let r = hier7()
      v = shift(ValueShr, l, r, ti)
    } else {
      break
    }
  }
  return v
}


let hier7 = func ValueParser {
  var v : *Value
  v = hier8()
  if v == Nil {return Nil}
  while True {
    let ti = &ctok().ti
    if match("+") {
      skip_nl()
      let l = v
      let r = hier8()
      v = bin(ValueAdd, l, r, ti)
    } else if match("-") {
      skip_nl()
      let l = v
      let r = hier8()
      v = bin(ValueSub, l, r, ti)
    } else {
      break
    }
  }
  return v
}


let hier8 = func ValueParser {
  var v : *Value
  v = hier9()
  if v == Nil {return Nil}
  while True {
    let ti = &ctok().ti
    if match("*") {
      skip_nl()
      let l = v
      let r = hier9()
      v = bin(ValueMul, l, r, ti)
    } else if match("/") {
      skip_nl()
      let l = v
      let r = hier9()
      v = bin(ValueDiv, l, r, ti)
    } else if match("%") {
      skip_nl()
      let l = v
      let r = hier9()
      v = bin(ValueMod, l, r, ti)
    } else {
      break
    }
  }
  return v
}


let hier9 = func ValueParser {
  var v : *Value
  v = hier10()
  if v == Nil {return Nil}
  let ti = &ctok().ti
  if match("to") {
    let t = parse_type()
    v = cast(v, t, ti)
  }
  return v
}


let hier10 = func ValueParser {
  var v : *Value
  let ti = &ctok().ti
  if match("*") {
    let r = hier10()
    v = un(ValueDeref, r, ti)
  } else if match("&") {
    let r = hier11()
    v = un(ValueRef, r, ti)
  } else if match("not") {
    let r = hier10()
    v = un(ValueNot, r, ti)
  } else if match("-") {
    let r = hier10()
    v = un(ValueMinus, r, ti)
  } else if match("sizeof") {
    let ti_sizeof = &ctok().ti
    let t = parse_type()
    if t == Nil {
      error("sizeof expected <type>", ti_sizeof)
      return Nil
    }
    v = size_of(t, ti)

  } else if match("alignof") {
    let ti_alignof = &ctok().ti
    let t = parse_type()
    if t == Nil {
      error("alignof expected <type>", ti_alignof)
      return Nil
    }
    v = align_of(t, ti)
  } else {
    v = hier11()
  }
  return v
}


let hier11 = func ValueParser {
  var v : *Value
  v = hier12()
  if v == Nil {return Nil}
  while True {
    let ti = &ctok().ti
    if match("(") {
      let arglist = list_new()
      while not match(")") {
        let a = expr()
        if a == Nil {
          skipto(",)")
          if match(",") {
            continue
          } else if match(")") {
            break
          } else {
            return Nil // unexpected EOF
          }
        }

        list_append(arglist, a)
        if not match(")") {
          need(",")
        } else {
          break
        }
      }
      v = call(v, arglist, ti)
    } else if match("[") {
      let i = expr()
      match("]")
      v = indx(v, i, ti)
    } else if match(".") {
      let field_id = parseId()
      v = access(v, field_id, ti)
    } else {
      break
    }
  }

  return v
}


let hier12 = func ValueParser {
  var v : *Value
  let ti = &ctok().ti
  if match("(") {
    v = expr()
    need(")")
  } else {
    v = term()
  }
  return v
}


let term = func ValueParser {
  let token = ctok()
  let tt = token.type

  var v : *Value
  v = Nil

  if tt == TokenId {
    if match("func") {
      v = term_func()
    } else if match("array") {
      v = term_arr()
    } else {
      v = term_id()
    }
  } else if tt == TokenNum {
    v = term_num()
  } else if tt == TokenString {
    v = term_str()
  } else if tt == TokenHash {
    v = term_hash()
  } else {
    error("term: unexpected token\n", &token.ti)
    printf("tt=%d\n", token.type)
    printf("token = %s\n", &token.text[0])
  }

  if v != Nil {
    v.ti = &token.ti
  }

  return v
}


let term_str = func ValueParser {
  let ti = &ctok().ti
  let text = &ctok().text to Str
  let len = strlen(text) + 1
  let s = dup(text)
  skip()

  let id = get_name_str()

  asmStringAdd(&asm0, id, s, len)

  // создаем значение для строки
  let v = valueNew(ValueId, ti)
  v.type = typeStr
  v.kind = ValueGlobalVar
  v.id = id
  return v
}


let term_arr = func ValueParser {
  let ti = &ctok().ti
  let of = parse_type()
  need("{")

  let data = list_new()  // of *Value

  var len : Nat32
  len = 0
  while not match("}") {
    let item = cexpr()
    if item == Nil {match(","); continue}
    let item2 = castIfNumericTo(item, typeBaseInt)
    len = len + 1
    list_append(data, item2)
    match(",")
  }

  let id = get_name_arr()
  let t = type_array_new(of, len, False)

  asmArrayAdd(&asm0, id, t, data)

  let v = valueNew(ValueId, ti)
  v.type = t
  v.kind = ValueGlobalConst
  v.id = id
  v.defined_at = ti
  return v
}


let term_func = func ValueParser {
  // сохраняем контекст
  let old_fctx = fctx

  let parent_block = fctx.cblock

  // инициализируем новый контекст функции
  fctx.cfunc = Nil   // current function
  fctx.cblock = Nil  // current block
  fctx.loop = 0      // we're in cycle semaphore (for break/continue)
  fctx.locno = 0     // local var no
  fctx.strno = 0     // local string no
  fctx.arrno = 0     // local array no
  fctx.recno = 0     // local record no

  let ti = &ctok().ti

  /* Get Id */
  let id = get_name_func()

  if id == Nil {
    printf("funcdef id fail")
    goto fail
  }

  let t = parse_type()

  if t == Nil {
    printf("funcdef type fail")
    goto fail
  }

  /*if t.kind != TypeFunction {
    error("expected func type", t.ti)
    goto fail
  }*/

  // создаем значение функции
  let fv = valueNew(ValueId, ti)
  fv.type = t

  if parent_block != Nil {
    list_append(parent_block.local_functions, fv)
  }

  fctx.cfunc = fv
  fv.kind = ValueGlobalConst
  fv.id = id
  fv.defined_at = ti

  // выставляем ссылку на текущую функцию
  fctx.cfunc = fv

  need("{")
  let block = doblock()
  fv.block = block  // для чека сохраняем сссылку на блок в самом значении

  asmFuncAdd(&asm0, id, t, block)
  fctx = old_fctx

  return fv
fail:
  fctx = old_fctx
  return Nil
}


let term_id = func ValueParser {
  let ti = &ctok().ti
  let id = parseId()
  if id == Nil {return Nil}

  let v = get_value(id)

  if v == Nil {
    let nv = valueNew(ValueId, ti)
    nv.id = id
    nv.declared_at = ti
    bind_value_global(id, nv)
    return nv
  }

  v.id = id
  return v

fail:
  return Nil
}


let term_num = func ValueParser {
  let ti = &ctok().ti
  var d : Int64
  let tok = ctok()
  if tok.text[0] == "0"[0] and tok.text[1] == "x"[0] {
    sscanf(&tok.text[2], "%llx", &d)
  } else {
    sscanf(&tok.text[0], "%lld", &d)
  }
  skip()

  let t = type_new(TypeNumeric)
  t.declared_at = ti
  let v = valueNewImm(t, d, ti)
  v.defined_at = ti
  return v
}


let term_hash = func ValueParser {
  return Nil
}


