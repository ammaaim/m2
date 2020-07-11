// m2/type/check

// здесь есть проблема с бесконечной рекурсией, см typeCheckRecord


// встретили неизвестный тип
// создали TypeUnknown
// встретили typedef - проверили если ae то заполняем ae из nt
// check сперва проверяет типы если есть TypeUnknown - ошибка
// еще check должен рекурсивно проверить типы на внутреннюю рекурсию но это потом


// неизвестный тип недопустим
// агрегатный тип не может включать в себя самого себя

// проверяем тип на наличие в нем TypeUnknown
// TypeUnknown недопустим
let typeCheck = func (t : *Type) -> Unit {
  //printf("typeCheck\n")
  if type_is_pointer(t) {
    typeCheckPointer(&t.pointer)
  } else if type_is_array(t) {
    typeCheck(t.array.of)
  } else if type_is_function(t) {
    typeCheckFunc(&t.function)
  } else if type_is_record(t) {
    typeCheckRecord(&t.record)
  } else if t.kind == TypeUnknown {
    error("unknown type", t.ti)
  }
}


let typeCheckPointer = func (p : *TypePointer) -> Unit {
  let to = p.to
  if to.kind == TypeUnknown {
    error("unknown type", to.ti)
  } else {
    typeCheck(to)
  }
}


let typeCheckFunc = func (f : *TypeFunc) -> Unit {
  typeCheck(f.to)  // check return type

  // check params
  let foreach_func_param = func ListForeachHandler {
    let p = data to *Field
    typeCheck(p.type)
  }
  list_foreach(f.params, foreach_func_param, Nil)
}


let typeCheckRecord = func (r : *TypeRecord) -> Unit {
  let foreach_struct_field = func ListForeachHandler {
    let f = data to *Field
    //typeCheck(f.type)  // возн беск рекурсия!
    /*if f.type.kind == TypeUnknown {
      error("unknown type", f.type.ti)
    }*/
  }
  list_foreach(r.fields, foreach_struct_field, Nil)
}


