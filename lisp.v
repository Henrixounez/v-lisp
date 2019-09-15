import os
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

fn (t Token) str() string {
  switch t.typ {
    case TokenType.boolean:
      if t.boolean {
        return '#t'
      } else {
        return '#f'
      }
    case TokenType.integer:
      return '$t.integer'
    case TokenType.float:
      return '$t.float'
    case TokenType.str:
      return '$t.stri'
    case TokenType.token_list:
      return '$t.token_list'
    case TokenType.cons:
      return '(${show_cons(t)})'
  }
  return ''
}

fn show_cons(t Token) string {
  if t.token_list.len == 1 {
    return '${t.token_list[0]}'
  }
  if t.token_list[1].typ == TokenType.token_list && t.token_list[1].token_list.len == 0 {
    return '${t.token_list[0]}'
  } else if t.token_list[1].typ == TokenType.cons {
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
    if tok.typ == TokenType.integer {
      res += tok.integer
    } else if tok.typ == TokenType.float {
      res += tok.float
      float = true
    }
  }
  if !float {
    return Token{typ: TokenType.integer, integer: int(res)}
  } else {
    return Token{typ: TokenType.float, float: res}
  }
}

fn min(expr Token) Token {
  mut res := 0.0
  mut float := false

  if expr.token_list.len == 1 {
    if expr.token_list[0].typ == TokenType.integer {
      res = -expr.token_list[0].integer
    } else if expr.token_list[0].typ == TokenType.float {
      res = -expr.token_list[0].float
      float = true
    }
  } else {
    if expr.token_list[0].typ == TokenType.integer {
      res = expr.token_list[0].integer
    } else if expr.token_list[0].typ == TokenType.float {
      res = expr.token_list[0].float
      float = true
    }
    expr_list := expr.token_list.right(1)
    for tok in expr_list {
      if tok.typ == TokenType.integer {
        res -= tok.integer
      } else if tok.typ == TokenType.float {
        res -= tok.float
        float = true
      }
    }
  }
  if !float {
    return Token{typ: TokenType.integer, integer: int(res)}
  } else {
    return Token{typ: TokenType.float, float: res}
  }
}

fn mul(expr Token) Token {
  mut res := 1.0
  mut float := false
  for tok in expr.token_list {
    if tok.typ == TokenType.integer {
      res *= tok.integer
    } else if tok.typ == TokenType.float {
      res *= tok.float
      float = true
    }
  }
  if !float {
    return Token{typ: TokenType.integer, integer: int(res)}
  } else {
    return Token{typ: TokenType.float, float: res}
  }
}

fn divi(expr Token) Token {
  mut res := 0.0

  if expr.token_list.len == 1 {
    if expr.token_list[0].typ == TokenType.integer {
      res = f32(1) / expr.token_list[0].integer
    } else if expr.token_list[0].typ == TokenType.float {
      res = f32(1) / expr.token_list[0].float
    }
  } else {
    if expr.token_list[0].typ == TokenType.integer {
      res = expr.token_list[0].integer
    } else if expr.token_list[0].typ == TokenType.float {
      res = expr.token_list[0].float
    }
    expr_list := expr.token_list.right(1)
    for tok in expr_list {
      if tok.typ == TokenType.integer {
        res /= tok.integer
      } else if tok.typ == TokenType.float {
        res /= tok.float
      }
    }
  }
  return Token{typ: TokenType.float, float: res}
}

fn mod(expr Token) Token {
  a := if expr.token_list[0].typ == TokenType.integer {
    expr.token_list[0].integer
  } else {
    int(expr.token_list[0].float) //Cant mod floats in v :(
  }
  b := if expr.token_list[1].typ == TokenType.integer {
    expr.token_list[1].integer
  } else {
    int(expr.token_list[1].float) //Cant mod floats in v :(
  }
  return Token{typ: TokenType.integer, integer: a % b}
}

fn lt(expr Token) Token {
  typ := expr.token_list[0].typ
  mut res := false
  if typ != expr.token_list[1].typ {
    panic('Not the same typ on lt')
  }
  if typ == TokenType.boolean {
    res = expr.token_list[0].boolean < expr.token_list[1].boolean
  }
  if typ == TokenType.integer {
    res = expr.token_list[0].integer < expr.token_list[1].integer
  }
  if typ == TokenType.float {
    res = expr.token_list[0].float < expr.token_list[1].float
  }
  if typ == TokenType.str {
    res = expr.token_list[0].stri < expr.token_list[1].stri
  }
  return Token{typ: TokenType.boolean, boolean: res}
}

fn cons(expr Token) Token {
  return Token{typ: TokenType.cons, token_list: [expr.token_list[0], expr.token_list[1]]}
}

fn car(expr Token) Token {
  return expr.token_list[0].token_list[0]
}

fn cdr(expr Token) Token {
  to_take := expr.token_list[0]
  if to_take.typ == TokenType.cons {
    return to_take.token_list[1]
  } else {
    return Token{typ: to_take.typ, token_list: to_take.token_list.right(1)}
  }
}

fn list(expr Token) Token {
  return Token{typ: TokenType.token_list, token_list: expr.token_list}
}

fn eq(expr Token) Token {
  typ := expr.token_list[0].typ
  mut res := false
  if typ != expr.token_list[1].typ {
    panic('Not the same typ on eq')
  }
  if typ == TokenType.boolean {
    res = expr.token_list[0].boolean == expr.token_list[1].boolean
  }
  if typ == TokenType.integer {
    res = expr.token_list[0].integer == expr.token_list[1].integer
  }
  if typ == TokenType.float {
    res = expr.token_list[0].float == expr.token_list[1].float
  }
  if typ == TokenType.str {
    res = expr.token_list[0].stri == expr.token_list[1].stri
  }
  return Token{typ: TokenType.boolean, boolean: res}
}

fn atom(expr Token) Token {
  res := expr.token_list[0].typ != TokenType.token_list && expr.token_list[0].typ != TokenType.cons
  return Token{typ: TokenType.boolean, boolean: res}
}

fn call_func(call Token, expr Token) Token {
  match call.function {
    Proc.plus => { return plus(expr) }
    Proc.min => { return min(expr) }
    Proc.mul => { return mul(expr) }
    Proc.div => { return divi(expr) }
    Proc.mod => { return mod(expr) }
    Proc.lt => { return lt(expr) }
    Proc.cons => { return cons(expr) }
    Proc.car => { return car(expr) }
    Proc.cdr => { return cdr(expr) }
    Proc.list => { return list(expr) }
    Proc.eq => { return eq(expr) }
    Proc.atom => { return atom(expr) }
  }
  return Token{typ: TokenType.str, stri: 'nothing'}
}

fn execute_list(expr Token, env mut Env) Token? {
  if expr.typ == TokenType.str {
    if expr.stri in env.define_nbr {
      nbr := env.define_nbr[expr.stri]
      return env.define[nbr]
    }
    else {
      return error('unknown $expr.stri')
    }
  } else if expr.typ == TokenType.integer || expr.typ == TokenType.float || expr.typ == TokenType.boolean {
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
      return Token{typ: TokenType.token_list, token_list: []Token}
    }
    call := execute_list(expr.token_list[0], mut env) or {
      return error(err)
    }
    typ := if call.function == Proc.cons { TokenType.cons } else { TokenType.token_list }
    mut new_expr := Token{typ: typ, token_list: []Token}
    for i := 1; i < expr.token_list.len; i++ {
      new_tok := execute_list(expr.token_list[i],mut env) or {
        return error(err)
      }
      new_expr.token_list << new_tok
    }
    return call_func(call, new_expr)
  }
  return Token{typ: TokenType.nothing}
}

fn parse_expr(expr mut []string) Token? {
  if expr.len <= 1 {
    return error('unexpected eof')
  }
  tok := expr[0]
  expr.delete(0)
  if tok == '#t' {
    return Token{typ: TokenType.boolean, boolean: true}
  }
  if tok == '#f' {
    return Token{typ: TokenType.boolean, boolean: false}
  }
  if tok == '\'' {
    mut new_list := Token{typ: TokenType.token_list, token_list: [Token{typ: TokenType.str, stri: 'quote'}]}
    new_expr := parse_expr(mut expr) or {
      return error(err)
    }
    new_list.token_list << new_expr
    return new_list
  }
  if tok == '(' {
    mut new_list := Token{typ: TokenType.token_list, token_list: []Token}
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
      return Token{typ: TokenType.float, float: tok.f32()}
    } else {
      return Token{typ: TokenType.integer, integer: tok.int()}
    }
  }
  return Token{typ: TokenType.str, stri: tok}
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
      Token{ typ: TokenType.function, function: Proc.plus},
      Token{ typ: TokenType.function, function: Proc.min},
      Token{ typ: TokenType.function, function: Proc.mul},
      Token{ typ: TokenType.function, function: Proc.div},
      Token{ typ: TokenType.function, function: Proc.mod},
      Token{ typ: TokenType.function, function: Proc.lt},
      Token{ typ: TokenType.function, function: Proc.cons},
      Token{ typ: TokenType.function, function: Proc.car},
      Token{ typ: TokenType.function, function: Proc.cdr},
      Token{ typ: TokenType.function, function: Proc.list},
      Token{ typ: TokenType.function, function: Proc.eq},
      Token{ typ: TokenType.function, function: Proc.atom}
    ]
  }
}

fn main() {
  env := init_env()
  mut rl := readline.Readline{}
  rl.enable_raw_mode2()
  mut line := rl.read_line('')
  for line != '' {
    execute_lisp(line.trim_space(), mut env)
    line = rl.read_line('')
  }
  rl.disable_raw_mode()
}