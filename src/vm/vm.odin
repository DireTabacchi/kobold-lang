package vm

import "core:fmt"

import "kobold:code"
import "kobold:object"

Op_Code :: code.Op_Code

STACK_MAX :: 4096

Virtual_Machine :: struct {
    chunk: code.Chunk,
    stack: [STACK_MAX]object.Value,
    globals: [dynamic]object.Global,
    //locals: [dynamic]object.Local,
    local_count: int,

    ip: int,
    sp: int,
}

vm_init :: proc(vm: ^Virtual_Machine, chunk: code.Chunk) {
    vm.chunk = chunk
    vm.ip = 0
    vm.sp = 0
    vm.local_count = 0
}

vm_destroy :: proc(vm: ^Virtual_Machine) {
    delete(vm.globals)
}

stack_pop :: proc(vm: ^Virtual_Machine) -> object.Value {
    val := vm.stack[vm.sp-1]
    vm.sp -= 1
    return val
}

stack_push :: proc(vm: ^Virtual_Machine, val: object.Value) {
    vm.stack[vm.sp] = val
    vm.sp += 1
}

run :: proc(vm: ^Virtual_Machine) {
    for {
        op_bc := vm.chunk.code[vm.ip]
        switch op_bc {
        case byte(Op_Code.PUSH):
            stack_push(vm, vm.chunk.constants[read_u16(vm)])
        case byte(Op_Code.POP):
            stack_pop(vm)
        case byte(Op_Code.ADD), byte(Op_Code.SUB), byte(Op_Code.MULT), byte(Op_Code.DIV), byte(Op_Code.MOD), byte(Op_Code.MODF),
        byte(Op_Code.EQ), byte(Op_Code.NEQ), byte(Op_Code.LSSR), byte(Op_Code.GRTR), byte(Op_Code.LEQ), byte(Op_Code.GEQ),
        byte(Op_Code.LAND), byte(Op_Code.LOR):
            exec_binary_op(vm, op_bc)
        case byte(Op_Code.NEG), byte(Op_Code.NOT):
            exec_unary_op(vm, op_bc)
        case byte(Op_Code.JMP):
            loc := read_u16(vm)
            vm.ip = int(loc)
        case byte(Op_Code.JF):
            exec_jump_false(vm)
        case byte(Op_Code.SETG):
            set_global(vm)
        case byte(Op_Code.GETG):
            get_global(vm)
        case byte(Op_Code.SETL):
            set_local(vm)
        case byte(Op_Code.GETL):
            get_local(vm)
        case byte(Op_Code.RET):
            return
        }
        vm.ip += 1
    }
}

set_global :: proc(vm: ^Virtual_Machine) {
    idx := read_u16(vm)
    val := stack_pop(vm)
    if idx == u16(len(vm.globals)) {
        append(&vm.globals, object.Global{ val })
    } else if idx < u16(len(vm.globals)) {
        global_val := &vm.globals[idx]
        global_val.value = val.value
    } else {
        fmt.eprintln("Runtime error: Unable to resolve global variable")

    }
}

get_global :: proc(vm: ^Virtual_Machine) {
    idx := read_u16(vm)
    global_val := vm.globals[idx]
    stack_push(vm, global_val)
}

// TODO: Need better strategy to handle locals
set_local :: proc(vm: ^Virtual_Machine) {
    stack_offset := read_u16(vm)
    if stack_offset == u16(vm.sp - 1) {
        vm.local_count += 1

    } else if stack_offset < u16(vm.sp - 1) {
        val := stack_pop(vm)
        vm.stack[stack_offset] = val
    }

    //stack_push(vm, val)
    //if idx == u16(len(vm.locals)) {
    //    append(&vm.locals, object.Local{ val, 0 })
    //} else if idx < u16(len(vm.locals)) {
    //    local_val := &vm.locals[idx]
    //    local_val.value = val.value
    //} else {
    //    fmt.eprintln("Runtime error: Unable to resolve local variable")
    //}
}

// TODO: see proc set_local
get_local :: proc(vm: ^Virtual_Machine) {
    offset := read_u16(vm)
    local_val := vm.stack[offset]
    stack_push(vm, local_val)
}

read_u16 :: proc(vm: ^Virtual_Machine) -> u16 {
    hi := vm.chunk.code[vm.ip+1]
    lo := vm.chunk.code[vm.ip+2]
    idx : u16 = (u16(hi) << 8) | u16(lo)
    vm.ip += 2
    return idx
}

exec_binary_op :: proc(vm: ^Virtual_Machine, op: byte) {
    switch op {
    case byte(Op_Code.ADD):
        b := stack_pop(vm)
        a := stack_pop(vm)
        res: object.Value
        #partial switch a.type {
        case .Integer:
            res.value = a.value.(i64) + b.value.(i64)
        case .Unsigned_Integer:
            res.value = a.value.(u64) + b.value.(u64)
        case .Float:
            res.value = a.value.(f64) + b.value.(f64)
        }
        res.type = a.type
        stack_push(vm, res)
    case byte(Op_Code.SUB):
        b := stack_pop(vm)
        a := stack_pop(vm)
        res: object.Value
        #partial switch a.type {
        case .Integer:
            res.value = a.value.(i64) - b.value.(i64)
        case .Unsigned_Integer:
            res.value = a.value.(u64) - b.value.(u64)
        case .Float:
            res.value = a.value.(f64) - b.value.(f64)
        }
        res.type = a.type
        stack_push(vm, res)
    case byte(Op_Code.MULT):
        b := stack_pop(vm)
        a := stack_pop(vm)
        res: object.Value
        #partial switch a.type {
        case .Integer:
            res.value = a.value.(i64) * b.value.(i64)
        case .Unsigned_Integer:
            res.value = a.value.(u64) * b.value.(u64)
        case .Float:
            res.value = a.value.(f64) * b.value.(f64)
        }
        res.type = a.type
        stack_push(vm, res)
    case byte(Op_Code.DIV):
        b := stack_pop(vm)
        a := stack_pop(vm)
        res: object.Value
        #partial switch a.type {
        case .Integer:
            res.value = a.value.(i64) / b.value.(i64)
        case .Unsigned_Integer:
            res.value = a.value.(u64) / b.value.(u64)
        case .Float:
            res.value = a.value.(f64) / b.value.(f64)
        }
        res.type = a.type
        stack_push(vm, res)
    case byte(Op_Code.MOD):
        b := stack_pop(vm)
        a := stack_pop(vm)
        res: object.Value
        #partial switch a.type {
        case .Integer:
            res.value = a.value.(i64) % b.value.(i64)
        case .Unsigned_Integer:
            res.value = a.value.(u64) % b.value.(u64)
        }
        res.type = a.type
        stack_push(vm, res)
    case byte(Op_Code.MODF):
        b := stack_pop(vm)
        a := stack_pop(vm)
        res: object.Value
        #partial switch a.type {
        case .Integer:
            res.value = a.value.(i64) %% b.value.(i64)
        case .Unsigned_Integer:
            res.value = a.value.(u64) %% b.value.(u64)
        }
        res.type = a.type
        stack_push(vm, res)
    case byte(Op_Code.EQ):
        b := stack_pop(vm)
        a := stack_pop(vm)
        res: object.Value
        #partial switch a.type {
        case .Integer:
            res.value = a.value.(i64) == b.value.(i64)
        case .Unsigned_Integer:
            res.value = a.value.(u64) == b.value.(u64)
        case .Float:
            res.value = a.value.(f64) == b.value.(f64)
        case .String:
            res.value = a.value.(string) == b.value.(string)
        case .Rune:
            res.value = a.value.(rune) == b.value.(rune)
        case .Boolean:
            res.value = a.value.(bool) == b.value.(bool)
        }
        res.type = .Boolean
        stack_push(vm, res)
    case byte(Op_Code.NEQ):
        b := stack_pop(vm)
        a := stack_pop(vm)
        res: object.Value
        #partial switch a.type {
        case .Integer:
            res.value = a.value.(i64) != b.value.(i64)
        case .Unsigned_Integer:
            res.value = a.value.(u64) != b.value.(u64)
        case .Float:
            res.value = a.value.(f64) != b.value.(f64)
        case .String:
            res.value = a.value.(string) != b.value.(string)
        case .Rune:
            res.value = a.value.(rune) != b.value.(rune)
        case .Boolean:
            res.value = a.value.(bool) != b.value.(bool)
        }
        res.type = .Boolean
        stack_push(vm, res)
    case byte(Op_Code.LSSR):
        b := stack_pop(vm)
        a := stack_pop(vm)
        res: object.Value
        #partial switch a.type {
        case .Integer:
            res.value = a.value.(i64) < b.value.(i64)
        case .Unsigned_Integer:
            res.value = a.value.(u64) < b.value.(u64)
        case .Float:
            res.value = a.value.(f64) < b.value.(f64)
        case .String:
            res.value = a.value.(string) < b.value.(string)
        case .Rune:
            res.value = a.value.(rune) < b.value.(rune)
        }
        res.type = .Boolean
        stack_push(vm, res)
    case byte(Op_Code.GRTR):
        b := stack_pop(vm)
        a := stack_pop(vm)
        res: object.Value
        #partial switch a.type {
        case .Integer:
            res.value = a.value.(i64) > b.value.(i64)
        case .Unsigned_Integer:
            res.value = a.value.(u64) > b.value.(u64)
        case .Float:
            res.value = a.value.(f64) > b.value.(f64)
        case .String:
            res.value = a.value.(string) > b.value.(string)
        case .Rune:
            res.value = a.value.(rune) > b.value.(rune)
        }
        res.type = .Boolean
        stack_push(vm, res)
    case byte(Op_Code.LEQ):
        b := stack_pop(vm)
        a := stack_pop(vm)
        res: object.Value
        #partial switch a.type {
        case .Integer:
            res.value = a.value.(i64) <= b.value.(i64)
        case .Unsigned_Integer:
            res.value = a.value.(u64) <= b.value.(u64)
        case .Float:
            res.value = a.value.(f64) <= b.value.(f64)
        case .String:
            res.value = a.value.(string) <= b.value.(string)
        case .Rune:
            res.value = a.value.(rune) <= b.value.(rune)
        }
        res.type = .Boolean
        stack_push(vm, res)
    case byte(Op_Code.GEQ):
        b := stack_pop(vm)
        a := stack_pop(vm)
        res: object.Value
        #partial switch a.type {
        case .Integer:
            res.value = a.value.(i64) >= b.value.(i64)
        case .Unsigned_Integer:
            res.value = a.value.(u64) >= b.value.(u64)
        case .Float:
            res.value = a.value.(f64) >= b.value.(f64)
        case .String:
            res.value = a.value.(string) >= b.value.(string)
        case .Rune:
            res.value = a.value.(rune) >= b.value.(rune)
        }
        res.type = .Boolean
        stack_push(vm, res)
    case byte(Op_Code.LAND):
        b := stack_pop(vm)
        a := stack_pop(vm)
        res: object.Value
        res.value = a.value.(bool) && b.value.(bool)
        res.type = .Boolean
        stack_push(vm, res)
    case byte(Op_Code.LOR):
        b := stack_pop(vm)
        a := stack_pop(vm)
        res: object.Value
        res.value = a.value.(bool) || b.value.(bool)
        res.type = .Boolean
        stack_push(vm, res)
    }
}

exec_unary_op :: proc(vm: ^Virtual_Machine, op: byte) {
    switch op {
    case byte(Op_Code.NEG):
        val := stack_pop(vm)
        #partial switch val.type {
        case .Integer:
            val.value = -val.value.(i64)
            stack_push(vm, val)
        case .Float:
            val.value = -val.value.(f64)
            stack_push(vm, val)
        }
    case byte(Op_Code.NOT):
        val := stack_pop(vm)
        val.value = !val.value.(bool)
        stack_push(vm,val)
    }
}

exec_jump_false :: proc(vm: ^Virtual_Machine) {
    cond := stack_pop(vm)
    loc := read_u16(vm)
    if !cond.value.(bool) {
        vm.ip = int(loc)
    }
}
