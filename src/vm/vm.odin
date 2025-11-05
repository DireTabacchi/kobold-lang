package vm

// TODO: VM frames and stack should probably be arena'd
// TODO: Don't change value mutability when assigning variables

import "core:fmt"
import "core:mem"

import "kobold:code"
import "kobold:object"
import proc_lib "kobold:object/procedure"

Op_Code :: code.Op_Code

FRAME_MAX :: 64
STACK_MAX :: FRAME_MAX * 255

Call_Frame :: struct {
    procedure: ^proc_lib.Procedure,
    ip: int,
    sp: int,
    bp: int,
}

Virtual_Machine :: struct {
    frames: [FRAME_MAX]^Call_Frame,
    frame_count: int,

    stack: []object.Value,
    globals: [dynamic]object.Global,
    procs: []^proc_lib.Procedure,
    builtin_procs: [dynamic]^proc_lib.Builtin_Proc,
    //locals: [dynamic]object.Local,
    local_count: int,

    //ip: int,
    //sp: int,
}

vm_init :: proc(vm: ^Virtual_Machine, main_proc: ^proc_lib.Procedure, procs: []^proc_lib.Procedure) {
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

    append(&vm.builtin_procs, &proc_lib.builtin_procs["println"])
    append(&vm.builtin_procs, &proc_lib.builtin_procs["print"])
    append(&vm.builtin_procs, &proc_lib.builtin_procs["len"])
    append(&vm.builtin_procs, &proc_lib.builtin_procs["clock"])
}

vm_destroy :: proc(vm: ^Virtual_Machine) {
    for g in vm.globals {
        if g.type == object.Value_Kind.Array {
            arr := g.value.(object.Array)
            delete(arr.data)
        }
    }
    delete(vm.globals)
    delete(vm.builtin_procs)
    for f := vm.frame_count-1; f >= 0; f -= 1 {
        frame := vm.frames[f]
        for frame.sp > frame.bp {
            if vm.stack[frame.sp].type == object.Value_Kind.Array {
                arr := vm.stack[frame.sp].value.(object.Array)
                delete(arr.data)
            }
            frame.sp -= 1
        }

        free(vm.frames[f])
    }
    delete(vm.stack)
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
            val := frame.procedure.chunk.constants[read_u16(vm)]
            push_val: object.Value
            if arr_val, is_arr := val.value.(object.Array); is_arr {
                push_arr: object.Array
                push_arr.len = arr_val.len
                push_arr.type = arr_val.type
                push_arr.data = make([]object.Value, arr_val.len)
                copy(push_arr.data, arr_val.data)
                push_val.type = object.Value_Kind.Array
                push_val.mutable = false
                push_val.value = push_arr
            } else {
                push_val = val
            }
            stack_push(vm, push_val)
            //print_stack(vm)
        case byte(Op_Code.POP):
            stack_pop(vm)
            //print_stack(vm)
        case byte(Op_Code.ADD), byte(Op_Code.SUB), byte(Op_Code.MULT), byte(Op_Code.DIV), byte(Op_Code.MOD), byte(Op_Code.MODF),
        byte(Op_Code.EQ), byte(Op_Code.NEQ), byte(Op_Code.LSSR), byte(Op_Code.GRTR), byte(Op_Code.LEQ), byte(Op_Code.GEQ),
        byte(Op_Code.LAND), byte(Op_Code.LOR):
            exec_binary_op(vm, op_bc)
            //print_stack(vm)
        case byte(Op_Code.NEG), byte(Op_Code.NOT):
            exec_unary_op(vm, op_bc)
            //print_stack(vm)
        case byte(Op_Code.JMP):
            loc := read_u16(vm)
            frame.ip = int(loc)
        case byte(Op_Code.JF):
            exec_jump_false(vm)
            //print_stack(vm)
        case byte(Op_Code.CALL):
            exec_call(vm)
        case byte(Op_Code.CALLBI):
            exec_builtin_call(vm)
        case byte(Op_Code.SETG):
            set_global(vm)
            //print_stack(vm)
        case byte(Op_Code.GETG):
            get_global(vm)
            //print_stack(vm)
        case byte(Op_Code.SETL):
            set_local(vm)
            //print_stack(vm)
        case byte(Op_Code.GETL):
            get_local(vm)
            //print_stack(vm)
        case byte(Op_Code.BLDARR):
            build_array(vm)
            //print_stack(vm)
        case byte(Op_Code.SETARR):
            set_array_elem(vm)
            //print_stack(vm)
        case byte(Op_Code.GETARR):
            get_array_elem(vm)
            //print_stack(vm)
        case byte(Op_Code.RET):
            if frame.procedure.type == proc_lib.Proc_Type.Proc {
                exec_return(vm)
                continue
            } else {
                return
            }
        }
        frame.ip += 1
    }
}

build_array :: proc(vm: ^Virtual_Machine) {
    size := read_u16(vm)
    val: object.Value
    val.type = object.Value_Kind.Array
    arr: object.Array
    arr.data = make([]object.Value, size)
    val_type := stack_pop(vm)
    arr.type = val_type.type
    arr.len = int(size)
    stack_push(vm,val_type)
    for i : u16 = 0; i < size; i += 1 {
        elem_val := stack_pop(vm)
        arr.data[i] = elem_val
    }
    val.value = arr
    stack_push(vm, val)
}

set_array_elem :: proc(vm: ^Virtual_Machine) {
    arr := stack_pop(vm)
    arr_idx := stack_pop(vm)
    val := stack_pop(vm)
    arr_val := arr.value.(object.Array)
    arr_idx_val := arr_idx.value.(i64)
    arr_val.data[arr_idx_val] = val
    arr.value = arr_val
    stack_push(vm, arr)
}

get_array_elem :: proc(vm: ^Virtual_Machine) {
    arr := stack_pop(vm)
    arr_idx := stack_pop(vm)
    arr_val := arr.value.(object.Array)
    arr_idx_val := arr_idx.value.(i64)
    val := arr_val.data[arr_idx_val]
    stack_push(vm, val)
    delete(arr_val.data)
}

exec_call :: proc(vm: ^Virtual_Machine) {
    idx := read_u16(vm)
    callee := vm.procs[idx]
    old_frame := vm.frames[vm.frame_count-1]
    new_frame, _ := mem.new(Call_Frame)
    new_frame.procedure = callee
    new_frame.ip = 0
    new_frame.bp = old_frame.sp - int(callee.arity)
    new_frame.sp = old_frame.sp
    vm.frames[vm.frame_count] = new_frame
    vm.frame_count += 1
}

exec_builtin_call :: proc(vm: ^Virtual_Machine) {
    idx := read_u16(vm)
    callee := vm.builtin_procs[idx]
    arg_count := read_byte(vm)
    if !callee.varargs {
        arg_count = callee.arity
    }

    args := make([]object.Value, arg_count)
    defer delete(args)

    for i := 0; i < int(arg_count); i += 1 {
        val := stack_pop(vm)
        args[i] = val
    }
    //print_stack(vm)
    ret_val := callee.exec(..args)
    for arg in args {
        if arg.type == object.Value_Kind.Array {
            arg_arr := arg.value.(object.Array)
            delete(arg_arr.data)
        }
    }
    if callee.return_type != object.Value_Kind.Nil {
        stack_push(vm, ret_val)
        //print_stack(vm)
    }
}

exec_return :: proc(vm: ^Virtual_Machine) {
    frame := vm.frames[vm.frame_count-1]
    ret_val: object.Value
    if frame.procedure.return_type != object.Value_Kind.Nil {
        val := stack_pop(vm)
        //print_stack(vm)
        if val.type == object.Value_Kind.Array {
            arr := val.value.(object.Array)
            ret_arr: object.Array
            ret_arr.len = arr.len
            ret_arr.type = arr.type
            ret_arr.data = make([]object.Value, arr.len)
            copy(ret_arr.data, arr.data)
            ret_val.type = object.Value_Kind.Array
            ret_val.value = ret_arr
            delete(arr.data)
        } else {
            ret_val = val
        }
        vm.frame_count -= 1
        caller_frame := vm.frames[vm.frame_count-1]
        caller_frame.sp = frame.bp
        for i := frame.bp; i < frame.sp; i += 1 {
            stack_val := vm.stack[i]
            if stack_val.type == object.Value_Kind.Array {
                if stack_val.value.(object.Array).data != nil {
                    delete(stack_val.value.(object.Array).data)
                }
            }
        }
        stack_push(vm, ret_val)
        //print_stack(vm)
    } else {
        vm.frame_count -= 1
        caller_frame := vm.frames[vm.frame_count-1]
        caller_frame.sp = frame.bp
        for i := frame.bp; i < frame.sp; i += 1 {
            stack_val := vm.stack[i]
            if stack_val.type == object.Value_Kind.Array {
                if stack_val.value.(object.Array).data != nil {
                    delete(stack_val.value.(object.Array).data)
                }
            }
        }
    }
    free(frame)
}

set_global :: proc(vm: ^Virtual_Machine) {
    idx := read_u16(vm)
    val := stack_pop(vm)
    if idx == u16(len(vm.globals)) {
        append(&vm.globals, object.Global{ val })
    } else if idx < u16(len(vm.globals)) {
        global_val := &vm.globals[idx]
        if old_val, is_arr := global_val.value.(object.Array); is_arr {
            delete(old_val.data)
        }
        global_val.value = val.value
    } else {
        fmt.eprintln("Runtime error: Unable to resolve global variable")

    }
}

get_global :: proc(vm: ^Virtual_Machine) {
    idx := read_u16(vm)
    global_val := vm.globals[idx]
    push_val: object.Value
    #partial switch val_subtype in global_val.value {
    case object.Array:
        arr: object.Array
        arr.len = val_subtype.len
        arr.type = val_subtype.type
        arr.data = make([]object.Value, val_subtype.len)
        copy(arr.data, val_subtype.data)
        push_val.type = object.Value_Kind.Array
        push_val.mutable = false
        push_val.value = arr
    case:
        push_val = global_val
    }
    stack_push(vm, push_val)
}

set_local :: proc(vm: ^Virtual_Machine) {
    frame := vm.frames[vm.frame_count-1]
    stack_offset := read_u16(vm)
    bp_offset := stack_offset + u16(frame.bp)
    if bp_offset == u16(frame.sp - 1) {
        vm.local_count += 1
    } else if bp_offset < u16(frame.sp - 1) {
        val := stack_pop(vm)
        if old_arr_val, is_arr := vm.stack[bp_offset].value.(object.Array); is_arr {
            delete(old_arr_val.data)
        }
        vm.stack[bp_offset] = val
    }
}

get_local :: proc(vm: ^Virtual_Machine) {
    frame := vm.frames[vm.frame_count-1]
    stack_offset := read_u16(vm)
    bp_offset := stack_offset + u16(frame.bp)
    local_val := vm.stack[bp_offset]
    push_val: object.Value
    #partial switch val_subtype in local_val.value {
    case object.Array:
        arr: object.Array
        arr.len = val_subtype.len
        arr.type = val_subtype.type
        arr.data = make([]object.Value, val_subtype.len)
        copy(arr.data, val_subtype.data)
        push_val.type = object.Value_Kind.Array
        push_val.mutable = false
        push_val.value = arr
    case:
        push_val = local_val
    }
    stack_push(vm, push_val)
}

read_u16 :: proc(vm: ^Virtual_Machine) -> u16 {
    frame := vm.frames[vm.frame_count-1]
    hi := frame.procedure.chunk.code[frame.ip+1]
    lo := frame.procedure.chunk.code[frame.ip+2]
    idx : u16 = (u16(hi) << 8) | u16(lo)
    frame.ip += 2
    return idx
}

read_byte :: proc(vm: ^Virtual_Machine) -> byte {
    frame := vm.frames[vm.frame_count-1]
    b := frame.procedure.chunk.code[frame.ip+1]
    frame.ip += 1
    return b
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

print_stack :: proc(vm: ^Virtual_Machine) {
    frame := vm.frames[vm.frame_count-1]
    fmt.println("======= STACK TOP =======")
    for i := frame.sp-1; i >= 0; i -= 1 {
        val := vm.stack[i]
        #partial switch val.type {
        case object.Value_Kind.Array:
            fmt.printfln("[ Array %p ]", raw_data(val.value.(object.Array).data))
        case:
            fmt.printfln("[ %v ]", val.value)
        }
    }
    fmt.println("======= STACK BOT =======")
}
