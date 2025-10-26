package vm

// TODO: Refactor VM for new execution interface with procedures
// TODO: VM frames and stack should probably be arena'd

import "core:fmt"

import "kobold:code"
import "kobold:object"

Op_Code :: code.Op_Code

FRAME_MAX :: 64
STACK_MAX :: FRAME_MAX * 255

Call_Frame :: struct {
    procedure: ^code.Procedure,
    ip: int,
    sp: int,
    bp: int,
}

Virtual_Machine :: struct {
    frames: [FRAME_MAX]^Call_Frame,
    frame_count: int,

    stack: []object.Value,
    globals: [dynamic]object.Global,
    procs: []^code.Procedure,
    //locals: [dynamic]object.Local,
    local_count: int,

    //ip: int,
    //sp: int,
}

vm_init :: proc(vm: ^Virtual_Machine, main_proc: ^code.Procedure, procs: []^code.Procedure) {
    frame := new(Call_Frame)
    vm.frames[vm.frame_count] = frame
    vm.frame_count += 1
    frame.procedure = main_proc
    frame.bp = 0
    frame.sp = 0
    frame.ip = 0
    vm.local_count = 0
    vm.stack = make([]object.Value, STACK_MAX)
    vm.procs = procs
}

vm_destroy :: proc(vm: ^Virtual_Machine) {
    delete(vm.globals)
    delete(vm.stack)
    for frame in vm.frames {
        free(frame)
    }
}

stack_pop :: proc(vm: ^Virtual_Machine) -> object.Value {
    frame := vm.frames[vm.frame_count-1]
    val := vm.stack[frame.sp-1]
    frame.sp -= 1
    return val
}

stack_push :: proc(vm: ^Virtual_Machine, val: object.Value) {
    frame := vm.frames[vm.frame_count-1]
    vm.stack[frame.sp] = val
    frame.sp += 1
}

run :: proc(vm: ^Virtual_Machine) {
    for {
        frame := vm.frames[vm.frame_count-1]
        op_bc := frame.procedure.chunk.code[frame.ip]
        switch op_bc {
        case byte(Op_Code.PUSH):
            stack_push(vm, frame.procedure.chunk.constants[read_u16(vm)])
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
            frame.ip = int(loc)
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
        frame.ip += 1
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

set_local :: proc(vm: ^Virtual_Machine) {
    frame := vm.frames[vm.frame_count-1]
    stack_offset := read_u16(vm)
    if stack_offset == u16(frame.sp - 1) {
        vm.local_count += 1

    } else if stack_offset < u16(frame.sp - 1) {
        val := stack_pop(vm)
        vm.stack[stack_offset] = val
    }
}

get_local :: proc(vm: ^Virtual_Machine) {
    offset := read_u16(vm)
    local_val := vm.stack[offset]
    stack_push(vm, local_val)
}

read_u16 :: proc(vm: ^Virtual_Machine) -> u16 {
    frame := vm.frames[vm.frame_count-1]
    hi := frame.procedure.chunk.code[frame.ip+1]
    lo := frame.procedure.chunk.code[frame.ip+2]
    idx : u16 = (u16(hi) << 8) | u16(lo)
    frame.ip += 2
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
        frame := vm.frames[vm.frame_count-1]
        frame.ip = int(loc)
    }
}
