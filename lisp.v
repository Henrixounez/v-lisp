module main

import readline

enum Proc {
  plus
  min
  mul
  div
  mod
  lt
  cons
  car
  cdr
  list
  eq
  atom
}

enum TokenType {
  nothing
  boolean
  integer
  float
  str
  token_list
  cons
  function
}

struct Token {
mut:
  typ TokenType
  boolean bool
  integer int
  float f32
  stri string
  function Proc
  token_list []Token
}

struct Env {
mut:
  define_nbr map[string]int
  define []Token
}

pub fn (t Token) str() string {
  match t.typ {
    .boolean {
      if t.boolean {
        return '#t'
      } else {
        return '#f'
      }
    }
    .integer { return '$t.integer' }
    .float { return '$t.float' }
    .str { return '$t.stri' }
    .token_list { return '$t.token_list' }
    .cons { return '(${show_cons(t)})' }
    else { return '' }
  }
}

fn show_cons(t Token) string {
  if t.token_list.len == 1 {
    return '${t.token_list[0]}'
  }
  if t.token_list[1].typ == .token_list && t.token_list[1].token_list.len == 0 {
    return '${t.token_list[0]}'
  } else if t.token_list[1].typ == .cons {
    return '${t.token_list[0]} ${show_cons(t.token_list[1])}'
  } else {
    //Apparently simple interpolation adds a space so i call str method
    return '${t.token_list[0]}. ${t.token_list[1].str()}'
  }
}

fn plus(expr Token) Token {
  mut res := 0.0
  mut float := false
  for tok in expr.token_list {
    if tok.typ == .integer {
      res += tok.integer
    } else if tok.typ == .float {
      res += tok.float
      float = true
    }
  }
  if !float {
    return Token{typ: .integer, integer: int(res)}
  } else {
    return Token{typ: .float, float: res}
  }
}

fn min(expr Token) Token {
  mut res := 0.0
  mut float := false

  if expr.token_list.len == 1 {
    if expr.token_list[0].typ == .integer {
      res = -expr.token_list[0].integer
    } else if expr.token_list[0].typ == .float {
      res = -expr.token_list[0].float
      float = true
    }
  } else {
    if expr.token_list[0].typ == .integer {
      res = expr.token_list[0].integer
    } else if expr.token_list[0].typ == .float {
      res = expr.token_list[0].float
      float = true
    }
    expr_list := expr.token_list[1..]
    for tok in expr_list {
      if tok.typ == .integer {
        res -= tok.integer
      } else if tok.typ == .float {
        res -= tok.float
        float = true
      }
    }
  }
  if !float {
    return Token{typ: .integer, integer: int(res)}
  } else {
    return Token{typ: .float, float: res}
  }
}

fn mul(expr Token) Token {
  mut res := 1.0
  mut float := false
  for tok in expr.token_list {
    if tok.typ == .integer {
      res *= tok.integer
    } else if tok.typ == .float {
      res *= tok.float
      float = true
    }
  }
  if !float {
    return Token{typ: .integer, integer: int(res)}
  } else {
    return Token{typ: .float, float: res}
  }
}

fn divi(expr Token) Token {
  mut res := 0.0

  if expr.token_list.len == 1 {
    if expr.token_list[0].typ == .integer {
      res = f32(1) / expr.token_list[0].integer
    } else if expr.token_list[0].typ == .float {
      res = f32(1) / expr.token_list[0].float
    }
  } else {
    if expr.token_list[0].typ == .integer {
      res = expr.token_list[0].integer
    } else if expr.token_list[0].typ == .float {
      res = expr.token_list[0].float
    }
    expr_list := expr.token_list[1..]
    for tok in expr_list {
      if tok.typ == .integer {
        res /= tok.integer
      } else if tok.typ == .float {
        res /= tok.float
      }
    }
  }
  return Token{typ: .float, float: res}
}

fn mod(expr Token) Token {
  a := if expr.token_list[0].typ == .integer {
    expr.token_list[0].integer
  } else {
    int(expr.token_list[0].float) //Cant mod floats in v :(
  }
  b := if expr.token_list[1].typ == .integer {
    expr.token_list[1].integer
  } else {
    int(expr.token_list[1].float) //Cant mod floats in v :(
  }
  return Token{typ: .integer, integer: a % b}
}

fn lt(expr Token) Token {
  typ := expr.token_list[0].typ
  mut res := false
  if typ != expr.token_list[1].typ {
    panic('Not the same typ on lt')
  }
  if typ == .boolean {
    res = expr.token_list[0].boolean < expr.token_list[1].boolean
  }
  if typ == .integer {
    res = expr.token_list[0].integer < expr.token_list[1].integer
  }
  if typ == .float {
    res = expr.token_list[0].float < expr.token_list[1].float
  }
  if typ == .str {
    res = expr.token_list[0].stri < expr.token_list[1].stri
  }
  return Token{typ: .boolean, boolean: res}
}

fn cons(expr Token) Token {
  return Token{typ: .cons, token_list: [expr.token_list[0], expr.token_list[1]]}
}

fn car(expr Token) Token {
  return expr.token_list[0].token_list[0]
}

fn cdr(expr Token) Token {
  to_take := expr.token_list[0]
  if to_take.typ == .cons {
    return to_take.token_list[1]
  } else {
    return Token{typ: to_take.typ, token_list: to_take.token_list[1..]}
  }
}

fn list(expr Token) Token {
  return Token{typ: .token_list, token_list: expr.token_list}
}

fn eq(expr Token) Token {
  typ := expr.token_list[0].typ
  mut res := false
  if typ != expr.token_list[1].typ {
    panic('Not the same typ on eq')
  }
  if typ == .boolean {
    res = expr.token_list[0].boolean == expr.token_list[1].boolean
  }
  if typ == .integer {
    res = expr.token_list[0].integer == expr.token_list[1].integer
  }
  if typ == .float {
    res = expr.token_list[0].float == expr.token_list[1].float
  }
  if typ == .str {
    res = expr.token_list[0].stri == expr.token_list[1].stri
  }
  return Token{typ: .boolean, boolean: res}
}

fn atom(expr Token) Token {
  res := expr.token_list[0].typ != .token_list && expr.token_list[0].typ != .cons
  return Token{typ: .boolean, boolean: res}
}

fn call_func(call Token, expr Token) Token {
  match call.function {
    .plus { return plus(expr) }
    .min { return min(expr) }
    .mul { return mul(expr) }
    .div { return divi(expr) }
    .mod { return mod(expr) }
    .lt { return lt(expr) }
    .cons { return cons(expr) }
    .car { return car(expr) }
    .cdr { return cdr(expr) }
    .list { return list(expr) }
    .eq { return eq(expr) }
    .atom { return atom(expr) }
    else { Token{typ: .nothing }}
  }
  return Token{typ: .str, stri: 'nothing'}
}

fn execute_list(expr Token, env mut Env) ?Token {
  if expr.typ == .str {
    if expr.stri in env.define_nbr {
      nbr := env.define_nbr[expr.stri]
      return env.define[nbr]
    }
    else {
      return error('unknown $expr.stri')
    }
  } else if expr.typ == .integer || expr.typ == .float || expr.typ == .boolean {
    return expr
  } else if expr.token_list.len >= 2 && expr.token_list[0].stri == 'quote' {
    return expr.token_list[1]
  } else if expr.token_list.len >= 3 && expr.token_list[0].stri == 'define' {
    new_tok := execute_list(expr.token_list[2], mut env) or {
      return error(err)
    }
    env.define_nbr[expr.token_list[1].stri] = env.define.len
    env.define << new_tok
  } else if expr.token_list.len >= 2 && expr.token_list[0].stri == 'cond' {
    for i := 1; i < expr.token_list.len; i++ {
      if expr.token_list[i].token_list.len < 2 {
        return error('cond list too small')
      }
      res := execute_list(expr.token_list[i].token_list[0], mut env) or {
        return error(err)
      }
      if res.boolean {
        return execute_list(expr.token_list[i].token_list[1], mut env)
      }
    }
  // } else if expr.token_list.len >= 3 && expr.token_list[0].stri == 'lambda' {
  } else {
    if expr.token_list.len == 0 {
      return Token{typ: .token_list, token_list: []}
    }
    call := execute_list(expr.token_list[0], mut env) or {
      return error(err)
    }
    typ := if call.function == .cons { TokenType.cons } else { TokenType.token_list }
    mut new_expr := Token{typ: typ, token_list: []}
    for i := 1; i < expr.token_list.len; i++ {
      new_tok := execute_list(expr.token_list[i],mut env) or {
        return error(err)
      }
      new_expr.token_list << new_tok
    }
    return call_func(call, new_expr)
  }
  return Token{typ: .nothing}
}

fn parse_expr(expr mut []string) ?Token {
  if expr.len <= 1 {
    return error('unexpected eof')
  }
  tok := expr[0]
  expr.delete(0)
  if tok == '#t' {
    return Token{typ: .boolean, boolean: true}
  }
  if tok == '#f' {
    return Token{typ: .boolean, boolean: false}
  }
  if tok == '\'' {
    mut new_list := Token{typ: .token_list, token_list: [Token{typ: .str, stri: 'quote'}]}
    new_expr := parse_expr(mut expr) or {
      return error(err)
    }
    new_list.token_list << new_expr
    return new_list
  }
  if tok == '(' {
    mut new_list := Token{typ: .token_list, token_list: []}
    for expr[0] != ')' {
      new_expr := parse_expr(mut expr) or {
        return error(err)
      }
      new_list.token_list << new_expr
      if expr.len == 1 {
        return error('unexpected eof')
      }
    }
    expr.delete(0)
    return new_list
  }
  if tok == ')' {
    return error('unexpected )')
  }
  if tok[0].is_digit() {
    if tok.contains('.') {
      return Token{typ: .float, float: tok.f32()}
    } else {
      return Token{typ: .integer, integer: tok.int()}
    }
  }
  return Token{typ: .str, stri: tok}
}

fn execute_lisp(line string, env mut Env) {
  mut expr := line.replace('(', '( ').replace(')', ' )').replace('\'', ' \' ').split(' ')
  expr << ' '
  for expr[0] != ' ' {
    expr_list := parse_expr(mut expr) or {
      println(err)
      return
    }
    result := execute_list(expr_list, mut env) or {
      println(err)
      return
    }
    if result.str() != '' {
      println(result)
    }
  }
}

fn init_env() Env {
  return Env{
    define_nbr: {
      '+': int(Proc.plus),
      '-': int(Proc.min),
      '*': int(Proc.mul),
      'div': int(Proc.div),
      'mod': int(Proc.mod),
      '<': int(Proc.lt),
      'cons': int(Proc.cons),
      'car': int(Proc.car),
      'cdr': int(Proc.cdr),
      'list': int(Proc.list),
      'eq?': int(Proc.eq),
      'atom?': int(Proc.atom)
    }
    define: [
      Token{ typ: .function, function: .plus},
      Token{ typ: .function, function: .min},
      Token{ typ: .function, function: .mul},
      Token{ typ: .function, function: .div},
      Token{ typ: .function, function: .mod},
      Token{ typ: .function, function: .lt},
      Token{ typ: .function, function: .cons},
      Token{ typ: .function, function: .car},
      Token{ typ: .function, function: .cdr},
      Token{ typ: .function, function: .list},
      Token{ typ: .function, function: .eq},
      Token{ typ: .function, function: .atom}
    ]
  }
}

fn main() {
  env := init_env()
  mut rl := readline.Readline{}
  mut line := rl.read_line('') or { exit }
  for line.len > 0 && line != '' {
    execute_lisp(line.trim_space(), mut env)
    line = ''
    line = rl.read_line('') or { exit }
  }
}