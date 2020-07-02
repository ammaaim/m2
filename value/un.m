// m2/value/un


type ValueUn = record {x : *Value}



let un = func (k : ValueKind, v : *Value, ti : *TokenInfo) -> *Value {
  if v == Nil {return Nil}

  if k == ValueRef {
    return un_ref(v, ti)
  } else if k == ValueDeref {
    return un_deref(v, ti)
  } else if k == ValueMinus {
    return un_minus(v, ti)
  } else if k == ValueNot {
    return un_not(v, ti)
  } else {
    assert(False, "value/un :: unknown value kind received")
  }

  return Nil
}


let un_minus = func (v : *Value, ti : *TokenInfo) -> *Value {
  if v.storage.class == StorageImmediate {
    return valueNewImm(v.type, -v.storage.val, ti)
  }

  let vx = valueNew(ValueMinus, StorageRegister, ti)
  vx.un.x = v
  return vx
}


let un_not = func (v : *Value, ti : *TokenInfo) -> *Value {
  if v.storage.class == StorageImmediate {
    return valueNewImm(v.type, not v.storage.val, ti)
  }

  let vx = valueNew(ValueNot, StorageRegister, ti)
  vx.un.x = v
  return vx
}


let un_ref = func (v : *Value, ti : *TokenInfo) -> *Value {
  if valueIsReadonly(v) {
    error("cannot ref constant value", v.ti)
  }

  let vx = valueNew(ValueRef, StorageRegister, ti)
  vx.un.x = v
  return vx
}


let un_deref = func (v : *Value, ti : *TokenInfo) -> *Value {
  let vx = valueNew(ValueDeref, StorageAddress, ti)
  vx.un.x = v
  return vx
}


let checkValueUnary = func (v : *Value) -> *Type {
  let a = v.un.x

  let t0 = checkValue(a)

  var t : *Type
  let k = v.kind
  if k == ValueRef {
    t = type_pointer_new(t0)
  } else if k == ValueDeref {
    if t0.kind != TypePointer {
      error("expected pointer\n", v.ti)
      return Nil
    }
    t = t0.pointer.to
  } else if k == ValueMinus {
    t = t0
  } else if k == ValueNot {
    t = t0
  }

  return t
}


